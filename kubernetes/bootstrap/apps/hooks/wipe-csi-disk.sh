#!/usr/bin/env bash

is_node_ready() {
    local node_ip=$1
    local ready_status
    ready_status=$(talosctl get machinestatus --output json | jq --raw-output --slurp ".[] | select(.node == \"$node_ip\") | .spec.status.ready")
    if [ "${ready_status}" == "true" ]; then
        return 0
    else
        return 1
    fi
}

wipe_csi_disk() {
    local disks
    disks=$(talosctl get disks --output json | jq --slurp --compact-output '
        map(select(.spec.model == env.CSI_DISK))
            | group_by(.node)
            | map({ (.[0].node): (map(.metadata.id) | join(" ")) })
            | add
    ')

    jq --raw-output 'to_entries[] | "\(.key) \(.value)"' <<< "${disks}" | while read -r ip disk; do
        if ! is_node_ready "$ip"; then
            talosctl --nodes "$ip" get disk "${disk}"
        fi
    done
}

main() {
    wipe_csi_disk
}

main
