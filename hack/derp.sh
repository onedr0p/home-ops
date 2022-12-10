#!/usr/bin/env bash

while read -r line; do declare -x "$line"; done < <(sops -d ./kubernetes/flux/vars/cluster-secrets.sops.yaml | yq eval '.stringData' - | sed 's/: /=/g')
while read -r line; do declare -x "$line"; done < <(yq eval '.data' ./kubernetes/flux/vars/cluster-settings.yaml | sed 's/: /=/g')

# envsubst < ./kubernetes/apps/home-automation/home-assistant/helmrelease.yaml
envsubst < <(cat "${1}") | kubectl apply -f -
