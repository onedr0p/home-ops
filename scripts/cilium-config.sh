#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC2155
export ROOT_DIR="$(git rev-parse --show-toplevel)"
# shellcheck disable=SC1091
source "$(dirname "${0}")/lib/common.sh"

function wait_for_crds() {
    local -r crds=(
        "ciliuml2announcementpolicies" "ciliumbgppeeringpolicies" "ciliumloadbalancerippools"
    )

    for crd in "${crds[@]}"; do
        until kubectl get crd "${crd}.cilium.io" &>/dev/null; do
            log info "Cilium CRD is not available. Retrying in 10 seconds..." "crd=${crd}"
            sleep 10
        done
    done
}

function apply_config() {
    log debug "Applying Cilium config"

    local -r cilium_config_dir="${ROOT_DIR}/kubernetes/apps/kube-system/cilium/config"

    if [[ ! -d "${cilium_config_dir}" ]]; then
        log fatal "No Cilium config directory found" "file=${cilium_config_dir}"
    fi

    if kubectl --namespace kube-system diff --kustomize "${cilium_config_dir}" &>/dev/null; then
        log info "Cilium config is up-to-date"
    else
        if kubectl apply --namespace kube-system --server-side --field-manager kustomize-controller --kustomize "${cilium_config_dir}" &>/dev/null; then
            log info "Cilium config applied successfully"
        else
            log fatal "Failed to apply Cilium config"
        fi
    fi
}

function main() {
    wait_for_crds
    apply_config
}

main "$@"
