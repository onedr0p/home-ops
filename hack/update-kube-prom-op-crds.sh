#!/bin/bash -eu

VERSION=$1

[ -z "${VERSION}" ] && echo "Pass prometheus-operator version as first comandline argument" && exit 1

FILES=(
  "monitoring.coreos.com_alertmanagerconfigs.yaml"
  "monitoring.coreos.com_alertmanagers.yaml"
  "monitoring.coreos.com_podmonitors.yaml"
  "monitoring.coreos.com_probes.yaml"
  "monitoring.coreos.com_prometheuses.yaml"
  "monitoring.coreos.com_prometheusrules.yaml"
  "monitoring.coreos.com_servicemonitors.yaml"
  "monitoring.coreos.com_thanosrulers.yaml"
)

# https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.45.0/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml

for file in "${FILES[@]}" ; do
    kubectl apply -f "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${VERSION}/example/prometheus-operator-crd/${file}"
done
