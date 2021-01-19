#!/bin/bash -eu

VERSION=$1

[ -z "${VERSION}" ] && echo "Pass prometheus-operator version as first comandline argument" && exit 1

FILES=(
  "crd-alertmanagerconfigs.yaml"
  "crd-alertmanagers.yaml"
  "crd-podmonitors.yaml"
  "crd-probes.yaml"
  "crd-prometheuses.yaml"
  "crd-prometheusrules.yaml"
  "crd-servicemonitors.yaml"
  "crd-thanosrulers.yaml"
)

for file in "${FILES[@]}" ; do
    kubectl apply -f "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${VERSION}/example/prometheus-operator-crd/${file}"
done
