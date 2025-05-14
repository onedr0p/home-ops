#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${0}")/lib/common.sh"

export LOG_LEVEL="debug"
export ROOT_DIR="$(git rev-parse --show-toplevel)"

# Apply the Talos configuration to all the nodes
function apply_talos_config() {
    log debug "Applying Talos configuration"

    local controlplane_file="${ROOT_DIR}/talos/controlplane.yaml.j2"
    local worker_file="${ROOT_DIR}/talos/worker.yaml.j2"

    if [[ ! -f ${controlplane_file} ]]; then
        log error "No Talos machine files found for controlplane" "file=${controlplane_file}"
    fi

    if [[ ! -f ${worker_file} ]]; then
        log warn "No Talos machine files found for worker" "file=${worker_file}"
    fi

    if ! nodes=$(talosctl config info --output json 2>/dev/null | jq --exit-status --raw-output '.nodes | join(" ")') || [[ -z "${nodes}" ]]; then
        log error "No Talos nodes found"
    fi

    # Check that all nodes have a Talos configuration file
    for node in ${nodes}; do
        local node_file="${ROOT_DIR}/talos/nodes/${node}.yaml.j2"

        if [[ ! -f "${node_file}" ]]; then
            log error "No Talos machine files found for node" "node=${node}" file="${node_file}"
        fi
    done

    # Apply the Talos configuration to the controlplane and worker nodes
    for node in ${nodes}; do
        local node_file="${ROOT_DIR}/talos/nodes/${node}.yaml.j2"

        local machine_type
        machine_type=$(yq '.machine.type' "${node_file}")

        log debug "Applying Talos node configuration" "node=${node}" "machine_type=${machine_type}"

        if ! machine_config=$(bash "${ROOT_DIR}/scripts/render-machine-config.sh" "${ROOT_DIR}/talos/${machine_type}.yaml.j2" "${node_file}") || [[ -z "${machine_config}" ]]; then
            exit 1
        fi

        log info "Talos node configuration rendered successfully" "node=${node}"

        if ! output=$(echo "${machine_config}" | talosctl --nodes "${node}" apply-config --insecure --file /dev/stdin 2>&1); then
            if [[ "${output}" == *"certificate required"* ]]; then
                log warn "Talos node is already configured, skipping apply of config" "node=${node}"
                continue
            fi
            log error "Failed to apply Talos node configuration" "node=${node}" "output=${output}"
        fi

        log info "Talos node configuration applied successfully" "node=${node}"
    done
}

# Bootstrap Talos on a controller node
function bootstrap_talos() {
    log debug "Bootstrapping Talos"

    if ! controller=$(talosctl config info --output json | jq --exit-status --raw-output '.endpoints[]' | shuf -n 1) || [[ -z "${controller}" ]]; then
        log error "No Talos controller found"
    fi

    log debug "Talos controller discovered" "controller=${controller}"

    until output=$(talosctl --nodes "${controller}" bootstrap 2>&1 || true) && [[ "${output}" == *"AlreadyExists"* ]]; do
        log info "Talos bootstrap in progress, waiting 10 seconds..." "controller=${controller}"
        sleep 10
    done

    log info "Talos is bootstrapped" "controller=${controller}"
}

# Fetch the kubeconfig from a controller node
function fetch_kubeconfig() {
    log debug "Fetching kubeconfig"

    if ! controller=$(talosctl config info --output json | jq --exit-status --raw-output '.endpoints[]' | shuf -n 1) || [[ -z "${controller}" ]]; then
        log error "No Talos controller found"
    fi

    if ! talosctl kubeconfig --nodes "${controller}" --force --force-context-name main "$(basename "${KUBECONFIG}")" &>/dev/null; then
        log error "Failed to fetch kubeconfig"
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

# CRDs to be applied before the helmfile charts are installed
function apply_crds() {
    log debug "Applying CRDs"

    local -r crds=(
        # renovate: datasource=github-releases depName=kubernetes-sigs/external-dns
        https://raw.githubusercontent.com/kubernetes-sigs/external-dns/refs/tags/v0.17.0/docs/sources/crd/crd-manifest.yaml
        # renovate: datasource=github-releases depName=kubernetes-sigs/gateway-api
        https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/experimental-install.yaml
        # renovate: datasource=github-releases depName=prometheus-operator/prometheus-operator
        https://github.com/prometheus-operator/prometheus-operator/releases/download/v0.82.2/stripped-down-crds.yaml
    )

    for crd in "${crds[@]}"; do
        if kubectl diff --filename "${crd}" &>/dev/null; then
            log info "CRDs are up-to-date" "crd=${crd}"
            continue
        fi
        if kubectl apply --server-side --filename "${crd}" &>/dev/null; then
            log info "CRDs applied" "crd=${crd}"
        else
            log error "Failed to apply CRDs" "crd=${crd}"
        fi
    done
}

# Resources to be applied before the helmfile charts are installed
function apply_resources() {
    log debug "Applying resources"

    local -r resources_file="${ROOT_DIR}/bootstrap/resources.yaml.j2"

    if ! output=$(render_template "${resources_file}") || [[ -z "${output}" ]]; then
        exit 1
    fi

    if echo "${output}" | kubectl diff --filename - &>/dev/null; then
        log info "Resources are up-to-date"
        return
    fi

    if echo "${output}" | kubectl apply --server-side --filename - &>/dev/null; then
        log info "Resources applied"
    else
        log error "Failed to apply resources"
    fi
}

# Disks in use by rook-ceph must be wiped before Rook is installed
function wipe_rook_disks() {
    log debug "Wiping Rook disks"

    # Skip disk wipe if Rook is detected running in the cluster
    # NOTE: Is there a better way to detect Rook / OSDs?
    if kubectl --namespace rook-ceph get kustomization rook-ceph &>/dev/null; then
        log warn "Rook is detected running in the cluster, skipping disk wipe"
        return
    fi

    if ! nodes=$(talosctl config info --output json 2>/dev/null | jq --exit-status --raw-output '.nodes | join(" ")') || [[ -z "${nodes}" ]]; then
        log error "No Talos nodes found"
    fi

    log debug "Talos nodes discovered" "nodes=${nodes}"

    # Wipe disks on each node that match the ROOK_DISK environment variable
    for node in ${nodes}; do
        if ! disks=$(talosctl --nodes "${node}" get disk --output json 2>/dev/null |
            jq --exit-status --raw-output --slurp '. | map(select(.spec.model == env.ROOK_DISK) | .metadata.id) | join(" ")') || [[ -z "${nodes}" ]]; then
            log error "No disks found" "node=${node}" "model=${ROOK_DISK}"
        fi

        log debug "Talos node and disk discovered" "node=${node}" "disks=${disks}"

        # Wipe each disk on the node
        for disk in ${disks}; do
            if talosctl --nodes "${node}" wipe disk "${disk}" &>/dev/null; then
                log info "Disk wiped" "node=${node}" "disk=${disk}"
            else
                log error "Failed to wipe disk" "node=${node}" "disk=${disk}"
            fi
        done
    done
}

# Apply Helm releases using helmfile
function apply_helm_releases() {
    log debug "Applying Helm releases with helmfile"

    local -r helmfile_file="${ROOT_DIR}/bootstrap/helmfile.yaml"

    if [[ ! -f "${helmfile_file}" ]]; then
        log error "File does not exist" "file=${helmfile_file}"
    fi

    if ! helmfile --file "${helmfile_file}" apply --hide-notes --skip-diff-on-install --suppress-diff --suppress-secrets; then
        log error "Failed to apply Helm releases"
    fi

    log info "Helm releases applied successfully"
}

function main() {
    check_env KUBECONFIG KUBERNETES_VERSION ROOK_DISK TALOS_VERSION
    check_cli helmfile jq kubectl kustomize minijinja-cli op talosctl yq

    if ! op whoami --format=json &>/dev/null; then
        log error "Failed to authenticate with 1Password CLI"
    fi

    # Bootstrap the Talos node configuration
    apply_talos_config
    bootstrap_talos
    fetch_kubeconfig

    # Apply resources and Helm releases
    wait_for_nodes
    wipe_rook_disks
    apply_crds
    apply_resources
    apply_helm_releases

    log info "Congrats! The cluster is bootstrapped and Flux is syncing the Git repository"
}

main "$@"
