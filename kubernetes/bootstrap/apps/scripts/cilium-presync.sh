#!/usr/bin/env bash

# renovate: datasource=github-releases depName=prometheus-operator/prometheus-operator
PROMETHEUS_OPERATOR_VERSION="v0.80.0"

install_prometheus_crds() {
    local crds=(
        "monitoring.coreos.com_alertmanagerconfigs.yaml"
        "monitoring.coreos.com_alertmanagers.yaml"
        "monitoring.coreos.com_podmonitors.yaml"
        "monitoring.coreos.com_probes.yaml"
        "monitoring.coreos.com_prometheusagents.yaml"
        "monitoring.coreos.com_prometheuses.yaml"
        "monitoring.coreos.com_prometheusrules.yaml"
        "monitoring.coreos.com_scrapeconfigs.yaml"
        "monitoring.coreos.com_servicemonitors.yaml"
        "monitoring.coreos.com_thanosrulers.yaml"
    )

    for crd in "${crds[@]}"; do
        kubectl apply \
            --server-side \
            --field-manager=kustomize-controller \
            --filename \
            "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${PROMETHEUS_OPERATOR_VERSION}/example/prometheus-operator-crd/${crd}"
    done
}

main() {
    install_prometheus_crds
}

main
