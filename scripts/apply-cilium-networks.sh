#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${0}")/lib/common.sh"

export LOG_LEVEL="debug"
export ROOT_DIR="$(git rev-parse --show-toplevel)"

function main() {
    check_cli kubectl

    wait_for_crds "ciliumbgppeeringpolicies.cilium.io"  "ciliuml2announcementpolicies.cilium.io" "ciliumloadbalancerippools.cilium.io"
    apply_config_file "kube-system" "${ROOT_DIR}/kubernetes/apps/kube-system/cilium/app/networks.yaml"
}

main "$@"
