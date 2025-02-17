#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC2155
export ROOT_DIR="$(git rev-parse --show-toplevel)"

# shellcheck disable=SC1091
source "$(dirname "${0}")/lib/common.sh"

# Apply the Talos configuration to all the nodes
function apply_talos_config() {
    log debug "Applying Talos configuration"

    local -r talos_machine_files=(
        "${ROOT_DIR}/talos/controlplane.yaml.j2"
        "${ROOT_DIR}/talos/worker.yaml.j2"
    )

    for file in "${talos_machine_files[@]}"; do
        if [[ ! -f "${file}" ]]; then
            log warn "File does not exist" "file=${file}"
            continue
        fi

        if ! nodes=$(talosctl config info --output json 2>/dev/null | jq --exit-status --raw-output '.nodes | join(" ")') || [[ -z "${nodes}" ]]; then
            log fatal "No Talos nodes found"
        fi

        log debug "Talos nodes discovered" "nodes=${nodes}"

        # Inject secrets into the talos node template
        if ! resources=$(minijinja-cli "${file}" | op inject 2>/dev/null) || [[ -z "${resources}" ]]; then
            log fatal "Failed to inject secrets" "file=${file}"
        fi

        # Apply the Talos configuration
        for node in ${nodes}; do
            log debug "Applying Talos node configuration" "node=${node}"

            if ! output=$(echo "${resources}" | talosctl --nodes "${node}" apply-config --config-patch "@${ROOT_DIR}/talos/patches/${node}.yaml" --insecure --file /dev/stdin 2>&1);
            then
                if [[ "${output}" == *"certificate required"* ]]; then
                    log warn "Talos node is already configured, skipping apply of config" "node=${node}"
                    continue
                fi
                log fatal "Failed to apply Talos node configuration" "node=${node}" "output=${output}"
            fi

            log info "Talos node configuration applied successfully" "node=${node}"
        done
    done
}

# Bootstrap Talos on a controller node
function bootstrap_talos() {
    log debug "Bootstrapping Talos"

    local bootstrapped=true

    if ! controller=$(talosctl config info --output json | jq --exit-status --raw-output '.endpoints[]' | shuf -n 1) || [[ -z "${controller}" ]]; then
        log fatal "No Talos controller found"
    fi

    log debug "Talos controller discovered" "controller=${controller}"

    until output=$(talosctl --nodes "${controller}" bootstrap 2>&1); do
        if [[ "${bootstrapped}" == true && "${output}" == *"AlreadyExists"* ]]; then
            log info "Talos is bootstrapped" "controller=${controller}"
            return
        fi

        bootstrapped=false

        log info "Talos bootstrap failed, retrying in 10 seconds..." "controller=${controller}"
        sleep 10
    done
}

# Fetch the kubeconfig from a controller node
function fetch_kubeconfig() {
    log debug "Fetching kubeconfig"

    if ! controller=$(talosctl config info --output json | jq --exit-status --raw-output '.endpoints[]' | shuf -n 1) || [[ -z "${controller}" ]]; then
        log fatal "No Talos controller found"
    fi

    if ! talosctl kubeconfig --nodes "${controller}" --force --force-context-name main "$(basename "${KUBECONFIG}")" &>/dev/null; then
        log fatal "Failed to fetch kubeconfig"
    fi

    log info "Kubeconfig fetched successfully"
}

# Talos requires the nodes to be 'Ready=False' before applying resources
function wait_for_nodes() {
    log debug "Waiting for nodes to be available"

    # Skip waiting if all nodes are 'Ready=True'
    if kubectl wait nodes --for=condition=Ready=True --all --timeout=10s &>/dev/null; then
        log info "Nodes are available and ready, skipping wait for nodes"
        return
    fi

    # Wait for all nodes to be 'Ready=False'
    until kubectl wait nodes --for=condition=Ready=False --all --timeout=10s &>/dev/null; do
        log info "Nodes are not available, waiting for nodes to be available. Retrying in 10 seconds..."
        sleep 10
    done
}

# Applications in the helmfile require Prometheus custom resources (e.g. servicemonitors)
function apply_prometheus_crds() {
    log debug "Applying Prometheus CRDs"

    local resources crds

    # Fetch resources using kustomize build
    if ! resources=$(kustomize build "https://github.com/prometheus-operator/prometheus-operator/?ref=${PROMETHEUS_OPERATOR_VERSION}" 2>/dev/null) || [[ -z "${resources}" ]]; then
        log fatal "Failed to fetch Prometheus CRDs, check the version or the repository URL"
    fi

    # Extract only CustomResourceDefinitions
    if ! crds=$(echo "${resources}" | yq '. | select(.kind == "CustomResourceDefinition")' 2>/dev/null) || [[ -z "${crds}" ]]; then
        log fatal "No CustomResourceDefinitions found in the fetched resources"
    fi

    # Check if the CRDs are up-to-date
    if echo "${crds}" | kubectl diff --filename - &>/dev/null; then
        log info "Prometheus CRDs are up-to-date"
        return
    fi

    # Apply the CRDs
    if echo "${crds}" | kubectl apply --server-side --filename - &>/dev/null; then
        log info "Prometheus CRDs applied successfully"
    else
        log fatal "Failed to apply Prometheus CRDs"
    fi
}

# The application namespaces are created before applying the resources
function apply_namespaces() {
    log debug "Applying namespaces"

    local -r apps_dir="${ROOT_DIR}/kubernetes/apps"

    if [[ ! -d "${apps_dir}" ]]; then
        log fatal "Directory does not exist" "directory=${apps_dir}"
    fi

    for app in "${apps_dir}"/*/; do
        namespace=$(basename "${app}")

        # Check if the namespace resources are up-to-date
        if kubectl get namespace "${namespace}" &>/dev/null; then
            log info "Namespace resource is up-to-date" "resource=${namespace}"
            continue
        fi

        # Apply the namespace resources
        if kubectl create namespace "${namespace}" --dry-run=client --output=yaml \
            | kubectl apply --server-side --filename - &>/dev/null;
        then
            log info "Namespace resource applied" "resource=${namespace}"
        else
            log fatal "Failed to apply namespace resource" "resource=${namespace}"
        fi
    done
}

# Secrets to be applied before the helmfile charts are installed
function apply_secrets() {
    log debug "Applying secrets"

    local -r secrets_file="${ROOT_DIR}/bootstrap/secrets.yaml.tpl"
    local resources

    if [[ ! -f "${secrets_file}" ]]; then
        log fatal "File does not exist" "file=${secrets_file}"
    fi

    # Inject secrets into the template
    if ! resources=$(op inject --in-file "${secrets_file}" 2>/dev/null) || [[ -z "${resources}" ]]; then
        log fatal "Failed to inject secrets" "file=${secrets_file}"
    fi

    # Check if the secret resources are up-to-date
    if echo "${resources}" | kubectl diff --filename - &>/dev/null; then
        log info "Secret resources are up-to-date"
        return
    fi

    # Apply secret resources
    if echo "${resources}" | kubectl apply --server-side --filename - &>/dev/null; then
        log info "Secret resources applied"
    else
        log fatal "Failed to apply secret resources"
    fi
}

# Disks in use by rook-ceph must be wiped before Rook is installed
function wipe_rook_disks() {
    log debug "Wiping Rook disks"

    # Skip disk wipe if Rook is detected running in the cluster
    # TODO: Better way to detect Rook?
    if kubectl --namespace rook-ceph get kustomization rook-ceph &>/dev/null; then
        log warn "Rook is detected running in the cluster, skipping disk wipe"
        return
    fi

    if ! nodes=$(talosctl config info --output json 2>/dev/null | jq --exit-status --raw-output '.nodes | join(" ")') || [[ -z "${nodes}" ]]; then
        log fatal "No Talos nodes found"
    fi

    log debug "Talos nodes discovered" "nodes=${nodes}"

    # Wipe disks on each node that match the ROOK_DISK environment variable
    for node in ${nodes}; do
        if ! disks=$(talosctl --nodes "${node}" get disk --output json 2>/dev/null \
            | jq --exit-status --raw-output --slurp '. | map(select(.spec.model == env.ROOK_DISK) | .metadata.id) | join(" ")') || [[ -z "${nodes}" ]];
        then
            log fatal "No disks found" node "${node}" "model=${ROOK_DISK}"
        fi

        log debug "Talos node and disk discovered" "node=${node}" "disks=${disks}"

        # Wipe each disk on the node
        for disk in ${disks}; do
            if talosctl --nodes "${node}" wipe disk "${disk}" &>/dev/null; then
                log info "Disk wiped" "node=${node}" "disk=${disk}"
            else
                log fatal "Failed to wipe disk" "node=${node}" "disk=${disk}"
            fi
        done
    done
}

# Apply Helm releases using helmfile
function apply_helm_releases() {
    log debug "Applying Helm releases with helmfile"

    local -r helmfile_file="${ROOT_DIR}/bootstrap/helmfile.yaml"

    if [[ ! -f "${helmfile_file}" ]]; then
        log fatal "File does not exist" "file=${helmfile_file}"
    fi

    if ! helmfile --file "${helmfile_file}" apply --hide-notes --skip-diff-on-install --suppress-diff --suppress-secrets; then
        log fatal "Failed to apply Helm releases"
    fi

    log info "Helm releases applied successfully"
}

function main() {
    # Verifications before bootstrapping the cluster
    check_env KUBERNETES_VERSION PROMETHEUS_OPERATOR_VERSION ROOK_DISK TALOS_VERSION
    check_cli helmfile jq kubectl kustomize op talosctl yq

    if ! op user get --me &>/dev/null; then
        log fatal "Failed to authenticate with 1Password CLI"
    fi

    # Bootstrap the Talos node configuration
    apply_talos_config
    bootstrap_talos
    fetch_kubeconfig

    # Wait for the nodes to be available
    wait_for_nodes

    # Bootstrap the cluster configuration
    apply_prometheus_crds
    apply_namespaces
    apply_secrets
    wipe_rook_disks
    apply_helm_releases
}

main "$@"
