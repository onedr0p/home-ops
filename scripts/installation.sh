#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC2155
export ROOT_DIR="$(git rev-parse --show-toplevel)"
# shellcheck disable=SC1091
source "$(dirname "${0}")/lib/common.sh"

# Apply the Talos configuration to all the nodes
function apply_talos_config() {
    log debug "Applying Talos configuration"

    local talos_controlplane_file="${ROOT_DIR}/talos/controlplane.yaml.j2"
    local talos_worker_file="${ROOT_DIR}/talos/worker.yaml.j2"

    if [[ ! -f ${talos_controlplane_file} ]]; then
        log fatal "No Talos machine files found for controlplane" "file=${talos_controlplane_file}"
    fi

    # Skip worker configuration if no worker file is found
    if [[ ! -f ${talos_worker_file} ]]; then
        log warn "No Talos machine files found for worker" "file=${talos_worker_file}"
        talos_worker_file=""
    fi

    # Apply the Talos configuration to the controlplane and worker nodes
    for file in ${talos_controlplane_file} ${talos_worker_file}; do
        if ! nodes=$(talosctl config info --output json 2>/dev/null | jq --exit-status --raw-output '.nodes | join(" ")') || [[ -z "${nodes}" ]]; then
            log fatal "No Talos nodes found"
        fi

        log debug "Talos nodes discovered" "nodes=${nodes}"

        # Inject secrets into the talos node templates
        if ! resources=$(minijinja-cli "${file}" | op inject 2>/dev/null) || [[ -z "${resources}" ]]; then
            log fatal "Failed to inject secrets" "file=${file}"
        fi

        # Apply the Talos configuration
        for node in ${nodes}; do
            log debug "Applying Talos node configuration" "node=${node}"

            node_patch_file="${ROOT_DIR}/talos/nodes/${node}.yaml"

            if [[ ! -f ${node_patch_file} ]]; then
                log fatal "No Talos node file found" "file=${node_patch_file}"
            fi

            if ! output=$(echo "${resources}" | talosctl --nodes "${node}" apply-config --config-patch "@${node_patch_file}" --insecure --file /dev/stdin 2>&1);
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

        # Set bootstrapped to false after the first attempt
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

# Resources to be applied before the helmfile charts are installed
function apply_resources() {
    log debug "Applying resources"

    local -r resources_file="${ROOT_DIR}/bootstrap/resources.yaml.j2"
    local resources

    if [[ ! -f "${resources_file}" ]]; then
        log fatal "File does not exist" "file=${resources_file}"
    fi

    # Inject secrets into the resources template
    if ! resources=$(minijinja-cli "${resources_file}" | op inject 2>/dev/null) || [[ -z "${resources}" ]]; then
        log fatal "Failed to inject resources" "file=${resources_file}"
    fi

    # Check if the resources are up-to-date
    if echo "${resources}" | kubectl diff --filename - &>/dev/null; then
        log info "Resources are up-to-date"
        return
    fi

    # Apply resources
    if echo "${resources}" | kubectl apply --server-side --filename - &>/dev/null; then
        log info "Resources applied"
    else
        log fatal "Failed to apply resources"
    fi
}

# Disks in use by rook-ceph must be wiped before Rook is installed
function wipe_rook_disks() {
    log debug "Wiping Rook disks"

    # Skip disk wipe if Rook is detected running in the cluster
    # TODO: Is there a better way to detect Rook / OSDs?
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
    check_env KUBERNETES_VERSION ROOK_DISK TALOS_VERSION
    check_cli helmfile jq kubectl kustomize minijinja-cli op talosctl yq

    if ! op user get --me &>/dev/null; then
        log fatal "Failed to authenticate with 1Password CLI"
    fi

    # Bootstrap the Talos node configuration
    apply_talos_config
    bootstrap_talos
    fetch_kubeconfig

    # Apply resources and Helm releases
    wait_for_nodes
    wipe_rook_disks
    apply_resources
    apply_helm_releases

    log info "Congrats! The cluster is bootstrapped and Flux is syncing the Git repository"
}

main "$@"
