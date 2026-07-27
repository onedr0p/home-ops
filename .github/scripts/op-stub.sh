#!/usr/bin/env bash
# Stand-in for `op inject` in CI: substitutes op://kubernetes/talos/<FIELD>
# references on stdin with fields from a `talosctl gen secrets` bundle
# (SECRETS_FILE). Unmapped references pass through and fail the render.
set -euo pipefail

ref_prefix="op://kubernetes/talos"

declare -A field_paths=(
    [MACHINE_CA_CRT]=".certs.os.crt"
    [MACHINE_CA_KEY]=".certs.os.key"
    [MACHINE_TOKEN]=".trustdinfo.token"
    [CLUSTER_CA_CRT]=".certs.k8s.crt"
    [CLUSTER_CA_KEY]=".certs.k8s.key"
    [CLUSTER_TOKEN]=".secrets.bootstraptoken"
    [CLUSTER_AGGREGATORCA_CRT]=".certs.k8saggregator.crt"
    [CLUSTER_AGGREGATORCA_KEY]=".certs.k8saggregator.key"
    [CLUSTER_ETCD_CA_CRT]=".certs.etcd.crt"
    [CLUSTER_ETCD_CA_KEY]=".certs.etcd.key"
    [CLUSTER_SERVICEACCOUNT_KEY]=".certs.k8sserviceaccount.key"
    [CLUSTER_SECRETBOXENCRYPTIONSECRET]=".secrets.secretboxencryptionsecret"
    [CLUSTER_ID]=".cluster.id"
    [CLUSTER_SECRET]=".cluster.secret"
)

input="$(cat)"
for field in "${!field_paths[@]}"; do
    value="$(yq -r -e "${field_paths[${field}]}" "${SECRETS_FILE}")"
    input="${input//"${ref_prefix}/${field}"/${value}}"
done
printf '%s\n' "${input}"
