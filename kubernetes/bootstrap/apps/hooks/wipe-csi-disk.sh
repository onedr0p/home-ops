#!/usr/bin/env bash

is_node_ready() {
    local node=$1
    local ready_status
    ready_status=$(talosctl get nodestatus --output json \
        | jq --raw-output --slurp ".[] | select(.node == \"$node\") | .spec.nodeReady")
    if [ "${ready_status}" == "true" ]; then
        return 0
    else
        return 1
    fi
}

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
        if ! is_node_ready "${node}"; then
            printf "Wiping disk %s on %s\n" "${disk}" "${node}"
            talosctl --nodes "${node}" get disk "${disk}"
        else
            printf "Node %s is already ready\n" "${node}"
        fi
    else
        printf "No matching disk found on %s\n" "${node}"
    fi
}

main() {
    local node disk

    for node in $(get_nodes); do
        printf "Getting disk id for %s\n" "${node}"
        disk=$(get_disk "${node}")
        wipe_disk "${node}" "${disk}"
    done
}

main
