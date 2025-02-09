#!/usr/bin/env bash

get_nodes() {
    talosctl config info --output json | jq --raw-output '.nodes | .[]'
}

get_disk() {
    local node=$1
    talosctl --nodes "${node}" get disks --output json \
        | jq --raw-output --slurp '. | map(select(.spec.model == env.ROOK_DISK) | .metadata.id) | join(" ")'
}

wipe_disk() {
    local node=$1
    local disk=$2

    if [[ -n "${disk}" ]]; then
        echo "Wiping disk ${disk} on ${node}..."
        talosctl --nodes "${node}" get disk "${disk}" # TODO: change get to wipe
    else
        echo "No matching disk found on ${node}"
    fi
}

main() {
    local node disk

    if kubectl --namespace rook-ceph get kustomization rook-ceph &>/dev/null; then
        echo "Rook is already installed"
        return
    fi

    for node in $(get_nodes); do
        wipe_disk "${node}" "$(get_disk "${node}")"
    done
}

main
