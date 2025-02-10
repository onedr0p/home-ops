#!/usr/bin/env bash

set -euo pipefail

function talos_nodes() {
    talosctl config info --output json \
        | jq --raw-output '.nodes | .[]'
}

function find_matching_disks() {
    local -r node=$1
    talosctl --nodes "${node}" get disks --output json \
        | jq --raw-output 'select(.spec.model == env.CSI_DISK) | .metadata.id' \
            | xargs
}

function wipe_disks() {
    local -r node=$1
    local -r disks=$2

    if [[ -n "${disks}" ]]; then
        echo "Wiping disk(s) '${disks}' on node '${node}'..."
        talosctl --nodes "${node}" wipe disk "${disks}"
    else
        echo "No matching disk found on node '${node}'"
    fi
}

function main() {
    local node

    if kubectl --namespace rook-ceph get kustomization rook-ceph &>/dev/null; then
        echo "Rook is already installed. Skipping..."
        return
    fi

    if [[ -z "${CSI_DISK}" ]]; then
        echo "CSI_DISK environment variable is not set. Skipping..."
        return
    fi

    for node in $(talos_nodes); do
        wipe_disks "${node}" "$(find_matching_disks "${node}")"
    done
}

main "$@"
