#!/usr/bin/env bash

wipe_csi_disks() {
    local nodes

    nodes=$(talosctl config info --output json | jq --raw-output '.nodes | .[]')
    for node in $nodes; do
        disks=$(
            talosctl --nodes "${node}" get disks --output json \
                | jq --raw-output 'select(.spec.model == env.CSI_DISK) | .metadata.id' \
                | xargs
        )

        if [[ -n "${disks}" ]]; then
            echo "Wiping disks ${disks} on node ${node}..."
            talosctl --nodes "${node}" wipe disk "${disks}"
        else
            echo "No disks found on node ${node}"
        fi
    done
}

main() {
    if kubectl --namespace rook-ceph get kustomization rook-ceph &>/dev/null; then
        echo "Rook is already installed"
        return
    fi

    wipe_csi_disks
}

main
