#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${0}")/lib/common.sh"

export LOG_LEVEL="debug"
export ROOT_DIR="$(git rev-parse --show-toplevel)"

function apply_config() {
    check_cli kubectl

    log debug "Applying Cilium networks"

    local -r cilium_networks_file="${ROOT_DIR}/kubernetes/apps/kube-system/cilium/app/networks.yaml"

    if [[ ! -d "${cilium_networks_file}" ]]; then
        log error "No Cilium networks file found" "file=${cilium_networks_file}"
    fi

    if kubectl --namespace kube-system diff --file "${cilium_networks_file}" &>/dev/null; then
        log info "Cilium networks are up-to-date"
    else
        if kubectl apply --namespace kube-system --server-side --field-manager kustomize-controller --file "${cilium_networks_file}" &>/dev/null; then
            log info "Cilium networks applied successfully"
        else
            log error "Failed to apply Cilium networks"
        fi
    fi
}

function main() {
    wait_for_crds "ciliuml2announcementpolicies.cilium.io" "ciliumbgppeeringpolicies.cilium.io" "ciliumloadbalancerippools.cilium.io"
    apply_config
}

main "$@"
