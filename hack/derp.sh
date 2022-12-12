#!/usr/bin/env bash

# while read -r line; do declare -x "$line"; done < <(sops -d ./kubernetes/flux/vars/cluster-secrets.sops.yaml | yq eval '.stringData' - | sed 's/: /=/g')
# while read -r line; do declare -x "$line"; done < <(yq eval '.data' ./kubernetes/flux/vars/cluster-settings.yaml | sed 's/: /=/g')

# # envsubst < ./kubernetes/apps/home-automation/home-assistant/helmrelease.yaml
# envsubst < <(cat "${1}") | kubectl apply -f -


query="$(kubectl -n default get deployment,statefulset --selector="app.kubernetes.io/name=plex" --no-headers 2>&1)"
if echo "${query}" | grep -q "No resources"; then
    echo "Controller not found in cluster"
else
    echo "${query}" | awk '{print $1}'
fi

query="$(kubectl -n default get persistentvolumeclaim --selector="app.kubernetes.io/name=plex" --no-headers 2>&1)"
if echo "${query}" | grep -q "No resources"; then
    echo "Claim not found in cluster"
else
    echo "${query}" | awk '{print $1}'
fi

query="$(kubectl -n default get helmrelease plex -o yaml 2>&1)"
if echo "${query}" | grep -q "NotFound"; then
    echo "Kustomization not found in cluster"
else
    echo "${query}" | yq eval '.metadata.labels."kustomize.toolkit.fluxcd.io/name"'
fi
