#!/usr/bin/env bash
set -Eeuo pipefail

# This script bootstraps a Talos-based Kubernetes cluster.
# It renders and applies Talos machine configurations, bootstraps Talos on controller nodes,
# fetches the kubeconfig, applies required CRDs and resources, and syncs Helm releases.
#
# Arguments:
#   None
#
# Example Usage:
#   ./bootstrap.sh
#
# Output:
#   Logs the bootstrap process and status messages to standard output.
#
# Note:
#   - This script is intended for clusters where all nodes have the same hardware configuration
#     (disk models, network devices, etc.) and schematic IDs.
#   - It does not support clusters with separate controller and worker node roles.

source "$(dirname "${0}")/lib/common.sh"

export LOG_LEVEL="debug"
export ROOT_DIR="$(git rev-parse --show-toplevel)"

# Apply the Talos configuration to all the nodes
function apply_talos_config() {
    log debug "Applying Talos configuration"

    local controlplane_file="${ROOT_DIR}/talos/controlplane.yaml.j2"

    if [[ ! -f ${controlplane_file} ]]; then
        log error "No Talos machine files found for controlplane" "file=${controlplane_file}"
    fi

    # Controlplane nodes are defined in talosconfig as endpoints
    if ! controlplane_nodes=$(yq '.contexts.main.endpoints | join (" ")' "${ROOT_DIR}/talosconfig")|| [[ -z "${controlplane_nodes}" ]]; then
        log error "No Talos controlplane nodes found"
    fi

    for node in ${controlplane_nodes}; do
        log debug "Applying Talos controlplane configuration" "node=${node}"

        if ! machine_config=$(minijinja-cli --define hostname="${node}" "${controlplane_file}" | op inject 2>/dev/null) || [[ -z "${machine_config}" ]]; then
            log error "Failed to render Talos controlplane configuration" "file=${controlplane_file}" "node=${node}"
        fi

        log info "Talos controlplane node configuration rendered successfully" "node=${node}"

        if ! output=$(echo "${machine_config}" | talosctl --nodes "${node}" apply-config --insecure --file /dev/stdin 2>&1); then
            if [[ "${output}" == *"certificate required"* ]]; then
                log warn "Talos controlplane node is already configured, skipping apply of config" "node=${node}"
                continue
            fi
            log error "Failed to apply Talos controlplane node configuration" "node=${node}" "output=${output}"
        fi

        log info "Talos controlplane node configuration applied successfully" "node=${node}"
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
        https://raw.githubusercontent.com/kubernetes-sigs/external-dns/refs/tags/v0.18.0/config/crd/standard/dnsendpoints.externaldns.k8s.io.yaml
        # renovate: datasource=github-releases depName=kubernetes-sigs/gateway-api
        https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/experimental-install.yaml
        # renovate: datasource=github-releases depName=prometheus-operator/prometheus-operator
        https://github.com/prometheus-operator/prometheus-operator/releases/download/v0.84.1/stripped-down-crds.yaml
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

    local -r resources_file="${ROOT_DIR}/bootstrap/resources.yaml"

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

# Sync Helm releases
function sync_helm_releases() {
    log debug "Syncing Helm releases"

    local -r helmfile_file="${ROOT_DIR}/bootstrap/helmfile.yaml"

    if [[ ! -f "${helmfile_file}" ]]; then
        log error "File does not exist" "file=${helmfile_file}"
    fi

    if ! helmfile --file "${helmfile_file}" sync --hide-notes; then
        log error "Failed to sync Helm releases"
    fi

    log info "Helm releases synced successfully"
}

function main() {
    check_env KUBECONFIG
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
    apply_crds
    apply_resources
    sync_helm_releases

    log info "Congrats! The cluster is bootstrapped and Flux is syncing the Git repository"
}

main "$@"
