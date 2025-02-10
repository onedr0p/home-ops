#!/usr/bin/env bash

set -euo pipefail

# renovate: datasource=github-releases depName=prometheus-operator/prometheus-operator
PROMETHEUS_OPERATOR_VERSION="v0.80.0"

function apply_crds() {
    local -r crds=(
        "alertmanagerconfigs"
        "alertmanagers"
        "podmonitors"
        "probes"
        "prometheusagents"
        "prometheuses"
        "prometheusrules"
        "scrapeconfigs"
        "servicemonitors"
        "thanosrulers"
    )

    for crd in "${crds[@]}"; do
        if kubectl get crd "${crd}.monitoring.coreos.com" &>/dev/null; then
            echo "The CRD '${crd}' already exists. Skipping..."
        else
            echo "Applying CRD '${crd}'..."
            kubectl apply \
                --server-side \
                --filename \
                "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${PROMETHEUS_OPERATOR_VERSION}/example/prometheus-operator-crd/monitoring.coreos.com_${crd}.yaml"
        fi
    done
}

function main() {
    apply_crds
}

main "$@"
