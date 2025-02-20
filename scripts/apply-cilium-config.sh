#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${0}")/lib/common.sh"

export LOG_LEVEL="debug"
export ROOT_DIR="$(git rev-parse --show-toplevel)"

function apply_config() {
    check_cli kubectl kustomize

    log debug "Applying Cilium config"

    local -r cilium_config_dir="${ROOT_DIR}/kubernetes/apps/kube-system/cilium/config"

    if [[ ! -d "${cilium_config_dir}" ]]; then
        log error "No Cilium config directory found" "directory=${cilium_config_dir}"
    fi

    if kubectl --namespace kube-system diff --kustomize "${cilium_config_dir}" &>/dev/null; then
        log info "Cilium config is up-to-date"
    else
        if kubectl apply --namespace kube-system --server-side --field-manager kustomize-controller --kustomize "${cilium_config_dir}" &>/dev/null; then
            log info "Cilium config applied successfully"
        else
            log error "Failed to apply Cilium config"
        fi
    fi
}

function main() {
    wait_for_crds "ciliuml2announcementpolicies.cilium.io" "ciliumbgppeeringpolicies.cilium.io" "ciliumloadbalancerippools.cilium.io"
    apply_config
}

main "$@"
