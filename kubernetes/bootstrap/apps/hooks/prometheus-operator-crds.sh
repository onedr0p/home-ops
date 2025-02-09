#!/usr/bin/env bash

# renovate: datasource=github-releases depName=prometheus-operator/prometheus-operator
PROMETHEUS_OPERATOR_VERSION="v0.80.0"

apply_crds() {
    local crds=(
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
        echo "Applying ${crd} CRD..."
        kubectl apply \
            --server-side \
            --filename \
            "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${PROMETHEUS_OPERATOR_VERSION}/example/prometheus-operator-crd/monitoring.coreos.com_${crd}.yaml"
    done
}

main() {
    apply_crds
}

main
