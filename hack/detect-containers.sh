#!/usr/bin/env bash

images=()

#
# helm releases with repository and tag
#

# pass
images+=("$(yq eval '[.. | select(has("repository")) | select(has("tag"))] | .[] | .repository + ":" + .tag' ./cluster/apps/home/home-assistant/helm-release.yaml)")
images+=("$(yq eval '[.. | select(has("repository")) | select(has("tag"))] | .[] | .repository + ":" + .tag' ./cluster/apps/monitoring/kube-prometheus-stack/helm-release.yaml)")
images+=("$(yq eval '[.. | select(has("repository")) | select(has("tag"))] | .[] | .repository + ":" + .tag' ./cluster/apps/kube-system/reflector/helm-release.yaml)")

# fail
images+=("$(yq eval '[.. | select(has("repository")) | select(has("tag"))] | .[] | .repository + ":" + .tag' ./cluster/apps/networking/cloudflare-ddns/cron-job.yaml)")
images+=("$(yq eval '[.. | select(has("repository")) | select(has("tag"))] | .[] | .repository + ":" + .tag' ./cluster/apps/networking/cloudflare-ddns/cron-job.yaml)")

#
# cron jobs
#

# pass
images+=("$(yq eval '.spec.jobTemplate.spec.template.spec.containers.[].image' ./cluster/apps/networking/cloudflare-ddns/cron-job.yaml)")

# fail
images+=("$(yq eval '.spec.jobTemplate.spec.template.spec.containers.[].image' ./cluster/apps/kube-system/reflector/helm-release.yaml)")
images+=("$(yq eval '.spec.jobTemplate.spec.template.spec.containers.[].image' ./ansible/storage/roles/apps.storage/templates/postgresql/docker-compose.yml.j2)")

#
# docker compose
#

# pass
images+=("$(yq eval '.services.*.image' ./ansible/storage/roles/apps.storage/templates/postgresql/docker-compose.yml.j2)")

# fail
images+=("$(yq eval '.services.*.image' ./cluster/apps/networking/cloudflare-ddns/cron-job.yaml)")
images+=("$(yq eval '.services.*.image' ./cluster/apps/kube-system/reflector/helm-release.yaml)")

# images+=("$(yq eval '.services.*.image' ./cluster/apps/kube-system/reflector/helm-raelease.yaml 2>/dev/null)")
# echo "${images[@]}"

parsed_images=()
for i in "${images[@]}"; do
    if [[ -n "${i}" && "${i}" != "null" ]]; then
        for b in ${i//\\n/ }; do
            parsed_images+=("${b}")
            # docker pull "${b}"
        done
    fi
done

jo -a -p "${parsed_images[@]}"

# jq -n --compact-output --argjson v "[$(printf '"%s",' "${parsed_images[@]}")0]" '$v'
