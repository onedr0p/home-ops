#!/usr/bin/env bash
set -eu
PROJECT_ROOT=$(git rev-parse --show-toplevel)
CLUSTER_ROOT="${PROJECT_ROOT}/cluster"

folders=$(find "${CLUSTER_ROOT}" -type d)

for folder in ${folders}; do
    pushd "${folder}" >/dev/null 2>&1
    # pwd
    echo "----${folder}----"
    files=$(find "${folder}" -maxdepth 1 -type f -iname "*.yaml")
    for file in ${files}; do
        echo "${file}"
    done
    popd >/dev/null 2>&1
done
