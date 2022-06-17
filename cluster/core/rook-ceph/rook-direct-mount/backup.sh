#!/usr/bin/env bash

# PVC=sonarr-config-v1 \
# NS=media \
# kubectl -n rook-ceph exec -it (kubectl -n rook-ceph get pod -l "app=rook-direct-mount" -o jsonpath='{.items[0].metadata.name}') -- /scripts/backup.sh --rbd (k get pv/(kubectl get pv | grep "$PVC" | awk -F' ' '{print $1}') -n "${NS}" -o json | jq -rj '.spec.csi.volumeAttributes.imageName') --pvc "$PVC"

# Set defaults
NFS_MOUNTPATH="/mnt/backups"
RBD_MOUNTPATH="/mnt/data"
CURRENT_DATE=$(date +"%FT%H%M")

# Script parameters
rbd=""
pvc=""

# Collect command line parameters
while [ $# -gt 0 ]; do
    if [[ "$1" == *"--"* ]]; then
        param="${1/--/}"
        declare "$param"="$2"
    fi
    shift
done

if [[ -z "${rbd}" ]]; then
    echo "Required parameter '--rbd' not set!"
    exit 1
fi

if [[ -z "${pvc}" ]]; then
    echo "Required parameter '--pvc' not set!"
    exit 1
fi

if ! mountpoint -q ${NFS_MOUNTPATH}; then
    echo "NFS mount '${NFS_MOUNTPATH}' is not mounted"
    exit 1
fi

if [[ ! -d "${RBD_MOUNTPATH}" ]]; then
    mkdir -p "${RBD_MOUNTPATH}"
fi

if [[ ! -d "${NFS_MOUNTPATH}/Manual" ]]; then
    mkdir -p "${NFS_MOUNTPATH}/Manual"
fi

if [[ -f "${NFS_MOUNTPATH}/${pvc}-${CURRENT_DATE}.tar.gz" ]]; then
    echo "File '${NFS_MOUNTPATH}/Manual/${pvc}-${CURRENT_DATE}.tar.gz' already exists"
    exit 1
fi

rbd map -p ceph-blockpool "${rbd}" | xargs -I{} mount {} "${RBD_MOUNTPATH}"
tar czvf "${NFS_MOUNTPATH}/Manual/${pvc}-${CURRENT_DATE}.tar.gz" -C "${RBD_MOUNTPATH}/" .
umount "${RBD_MOUNTPATH}"
rbd unmap -p ceph-blockpool "${rbd}"
