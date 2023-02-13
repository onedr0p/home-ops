#!/usr/bin/env bash

# while read -r line; do declare -x "$line"; done < <(sops -d ./kubernetes/flux/vars/cluster-secrets.sops.yaml | yq eval '.stringData' - | sed 's/: /=/g')
# while read -r line; do declare -x "$line"; done < <(yq eval '.data' ./kubernetes/flux/vars/cluster-settings.yaml | sed 's/: /=/g')

# # envsubst < ./kubernetes/apps/home-automation/home-assistant/helmrelease.yaml
# envsubst < <(cat "${1}") | kubectl apply -f -


# query="$(kubectl -n default get deployment,statefulset --selector="app.kubernetes.io/name=plex" --no-headers 2>&1)"
# if echo "${query}" | grep -q "No resources"; then
#     echo "Controller not found in cluster"
# else
#     echo "${query}" | awk '{print $1}'
# fi

# query="$(kubectl -n default get persistentvolumeclaim --selector="app.kubernetes.io/name=plex" --no-headers 2>&1)"
# if echo "${query}" | grep -q "No resources"; then
#     echo "Claim not found in cluster"
# else
#     echo "${query}" | awk '{print $1}'
# fi

# query="$(kubectl -n default get helmrelease plex -o yaml 2>&1)"
# if echo "${query}" | grep -q "NotFound"; then
#     echo "Kustomization not found in cluster"
# else
#     echo "${query}" | yq eval '.metadata.labels."kustomize.toolkit.fluxcd.io/name"'
# fi


# while true; do
#   if kubectl wait --for=condition=complete --timeout=0 job/name 2>/dev/null; then
#     job_result=0
#     break
#   fi

#   if kubectl wait --for=condition=failed --timeout=0 job/name 2>/dev/null; then
#     job_result=1
#     break
#   fi

#   sleep 3
# done

# if [[ $job_result -eq 1 ]]; then
#     echo "Job failed!"
#     exit 1
# fi

# echo "Job succeeded"


# [[ -z $(kubectl -n default get persistentvolumeclaim immich-nfs -o jsonpath='{.metadata.labels.app\.kubernetes\.io/name}') ]] || exit 1

# [[ -z $(kubectl -n default get persistentvolumeclaim config-zzztest-0 -o jsonpath='{.metadata.labels.app\.kubernetes\.io/name}') ]] || echo "zzztest"

# Say this file changed
# ./kubernetes/apps/actions-runner-system/actions-runner-controller/app/helmrelease.yaml

# Get the ks.yaml file in
# ./kubernetes/apps/actions-runner-system/actions-runner-controller/

# Use yq eval-all to extract ks name and path
# yq eval-all '.metadata.name' kubernetes/apps/cert-manager/cert-manager/ks.yaml
# yq eval-all '.spec.path' kubernetes/apps/cert-manager/cert-manager/ks.yaml

# Pass the extracted values to flux build

# flux build ks cluster-apps --kustomization-file kubernetes/flux/apps.yaml --path kubernetes/apps/ \
#     | kubeconform -kubernetes-version 1.24.8 -schema-location default \
#         -schema-location '/tmp/derp/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
#             -summary

# flux build ks cluster-apps-radarr-app --kustomization-file kubernetes/apps/default/radarr/ks.yaml --path kubernetes/apps/default/radarr/ \
#     | kubeconform -kubernetes-version 1.24.8 -schema-location default \
#         -schema-location '/tmp/derp/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
#             -summary

# flux diff kustomization cluster-apps-radarr-app \
#     --kustomization-file kubernetes/apps/default/radarr/ks.yaml \
#     --path kubernetes/apps/default/radarr/


flux suspend hr -n default bazarr; kubectl scale sts bazarr --replicas 0
flux suspend hr -n default frigate; kubectl scale sts frigate --replicas 0
flux suspend hr -n default immich-machine-learning; kubectl scale deploy immich-machine-learning --replicas 0
flux suspend hr -n default immich-microservices; kubectl scale deploy immich-microservices --replicas 0
flux suspend hr -n default immich-server; kubectl scale deploy immich-server --replicas 0
flux suspend hr -n default immich-web; kubectl scale deploy immich-web --replicas 0
flux suspend hr -n default jellyfin; kubectl scale sts jellyfin --replicas 0
flux suspend hr -n default lidarr; kubectl scale sts lidarr --replicas 0
flux suspend hr -n default media-browser; kubectl scale sts media-browser --replicas 0
flux suspend hr -n default navidrome; kubectl scale sts navidrome --replicas 0
flux suspend hr -n default plex; kubectl scale sts plex --replicas 0
flux suspend hr -n default qbittorrent; kubectl scale sts qbittorrent --replicas 0
flux suspend hr -n default radarr; kubectl scale sts radarr --replicas 0
flux suspend hr -n default sabnzbd; kubectl scale sts sabnzbd --replicas 0
flux suspend hr -n default sonarr; kubectl scale sts sonarr --replicas 0
flux suspend hr -n default unpackerr; kubectl scale deploy unpackerr --replicas 0

flux resume hr -n default bazarr
flux resume hr -n default frigate
flux resume hr -n default immich-machine-learning
flux resume hr -n default immich-microservices
flux resume hr -n default immich-server
flux resume hr -n default immich-web
flux resume hr -n default jellyfin
flux resume hr -n default lidarr
flux resume hr -n default media-browser
flux resume hr -n default navidrome
flux resume hr -n default plex
flux resume hr -n default qbittorrent
flux resume hr -n default radarr
flux resume hr -n default sabnzbd
flux resume hr -n default sonarr
flux resume hr -n default unpackerr

