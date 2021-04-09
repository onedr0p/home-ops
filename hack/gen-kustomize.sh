#!/usr/bin/env bash
set -eu
PROJECT_ROOT=$(git rev-parse --show-toplevel)
CLUSTER_ROOT="${PROJECT_ROOT}/cluster"

# Create cluster kustomization
pushd "${CLUSTER_ROOT}" >/dev/null 2>&1
if [ ! -f "kustomization.yaml" ]; then
    kustomize create
fi
kustomize edit add resource *
popd >/dev/null 2>&1

# Create all other kustomizations
folders=$(find "${CLUSTER_ROOT}"/ -type d)
for folder in ${folders}; do
    if [[ $folder =~ "flux-system" ]]; then
        continue
    fi

    pushd "${folder}" >/dev/null 2>&1
    ls *.yaml >/dev/null 2>&1 || continue
    if [ ! -f "kustomization.yaml" ]; then
        kustomize create
    fi
    kustomize edit add resource **.yaml
    popd >/dev/null 2>&1
done
