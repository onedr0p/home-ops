#!/usr/bin/env bash

# images=()
# image1=$(grep -oP "(?<=image:).*" cluster/apps/media/plex/helm-release.yaml | tr -d "[:blank:]")
# image2=$(grep -oP "(?<=image:).*" ansible/storage/roles/apps.storage/templates/cadvisor/docker-compose.yml.j2 | tr -d "[:blank:]")
# images+=( "${image1}" "${image2}" )

# for t in "${images[@]}"; do
#     if [[ -n "${t}" ]]; then
#         echo "z ${t}"
#     fi
# done


image=$(yq e '.services.*.image' ansible/storage/roles/apps.storage/templates/postgresql/docker-compose.yml.j2)
if [[ "${image}" != "null" ]]; then
    repository=$(yq e '.spec.values.image.repository' cluster/apps/media/plex/helm-release.yaml)
    tag=$(yq e '.spec.values.image.tag' cluster/apps/media/plex/helm-release.yaml)
    image="${repository}:${tag}"
fi

for i in ${image//\\n/ }
do
    docker pull "${i}"
done
