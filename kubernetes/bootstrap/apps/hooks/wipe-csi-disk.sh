#!/usr/bin/env bash

get_nodes() {
    talosctl config info --output json \
        | jq --raw-output '.nodes | .[]'
}

get_disk() {
    local node=$1
    talosctl --nodes "${node}" get disks --output json \
        | jq --raw-output --slurp '. | map(select(.spec.model == env.CSI_DISK) | .metadata.id) | join(" ")'
}

wipe_disk() {
    local node=$1
    local disk=$2

    if [[ -n "${disk}" ]]; then
        printf "Wiping disk %s on %s\n" "${disk}" "${node}"
        talosctl --nodes "${node}" get disk "${disk}" # TODO: change to wipe
    else
        printf "No matching disk found on %s\n" "${node}"
    fi
}

main() {
    local node disk

    if kubectl --namespace rook-ceph get kustomization rook-ceph &>/dev/null; then
        printf "Rook is already installed\n"
        return
    fi

    for node in $(get_nodes); do
        printf "Getting disk id for %s\n" "${node}"
        disk=$(get_disk "${node}")
        wipe_disk "${node}" "${disk}"
    done
}

main
