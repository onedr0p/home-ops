#!/usr/bin/env bash
# A script that applies a kustomization path with substituting
# the cluster config and secret vars in the KUSTOMIZATION_PATH
# ./hack/sopsubst.sh ./kubernetes/apps/monitoring/kube-prometheus-stack/app

KUSTOMIZATION_PATH="${1}"

# Paths to cluster secrets and config
cluster_secret_file="./kubernetes/flux/vars/cluster-secrets.sops.yaml"
cluster_config_file="./kubernetes/flux/vars/cluster-settings.yaml"

# Export vars in the config and secret files to the current env
while read -r line; do declare -x "${line}"; done < <(sops -d "${cluster_secret_file}" | yq eval '.stringData' - | sed 's/: /=/g')
while read -r line; do declare -x "${line}"; done < <(yq eval '.data' "${cluster_config_file}" | sed 's/: /=/g')

# Build the manifests in KUSTOMIZATION_PATH, substitute env with the variables and then apply to the cluster
kustomize build --load-restrictor=LoadRestrictionsNone "${KUSTOMIZATION_PATH}" \
    | envsubst \
        | kubectl apply --server-side -f -
