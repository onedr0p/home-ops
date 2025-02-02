#!/usr/bin/env bash

wait_for_crds() {
    local crds=(
        "ciliuml2announcementpolicies.cilium.io"
        "ciliumbgppeeringpolicies.cilium.io"
        "ciliumloadbalancerippools.cilium.io"
    )

    for crd in "${crds[@]}"; do
        until kubectl get crd "$crd" &>/dev/null; do
            sleep 5
        done
    done
}

apply_kustomize_config() {
    kubectl apply \
        --namespace=kube-system \
        --server-side \
        --field-manager=kustomize-controller \
        --kustomize \
        "${KUBERNETES_DIR}/apps/kube-system/cilium/config"
}

main() {
    wait_for_crds
    apply_kustomize_config
}

main
