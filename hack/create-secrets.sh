#!/usr/bin/env bash

# Wire up the env and validations
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${__dir}/environment.sh"


# Create secrets file
truncate -s 0 "${GENERATED_SECRETS}"

#
# Helm Secrets
#

# Generate Helm Secrets
txt=$(find "${CLUSTER_ROOT}" -type f -name "helmsecrets.txt")

if [[ ( -n $txt ) ]];
then
    # shellcheck disable=SC2129
    printf "%s\n%s\n%s\n" "#" "# Auto-generated helm secrets -- DO NOT EDIT." "#" >> "${GENERATED_SECRETS}"

    for file in "${CLUSTER_ROOT}"/**/helmsecrets.txt; do
        # Get the absolute directory path of the helmsecrets file
        # e.g. "/Users/devin/Code/homelab/home-cluster/cluster/media/flood"
        secret_path="$(dirname "$file")"
        # Get the last folder name
        # e.g. "flood"
        secret_name=$(basename "${secret_path}")
        # Get the namespace (based on parent folder path of helmsecrets.txt)
        # e.g. "media"
        namespace=$(basename "$(dirname "${secret_path}")")
        echo "[*] Generating helm secret '${secret_name}' in namespace '${namespace}'..."
        # Create secret
        envsubst < "$file" |
            # Create the Kubernetes secret
            kubectl -n "${namespace}" create secret generic "${secret_name}-helm-values" \
                --from-file=/dev/stdin --dry-run=client -o json |
            # Seal the Kubernetes secret
            kubeseal --format=yaml --cert="${PUB_CERT}" |
            # Remove null keys
            yq eval 'del(.metadata.creationTimestamp)' - |
            yq eval 'del(.spec.template.metadata.creationTimestamp)' - |
            # Format yaml file
            sed \
                -e 's/stdin\:/values.yaml\:/g' \
                -e '/^[[:space:]]*$/d' \
                -e '1s/^/---\n/' |
            # Write secret
            tee -a "${GENERATED_SECRETS}" >/dev/null 2>&1
    done
fi

#
# Generic Secrets
#

# shellcheck disable=SC2129
printf "%s\n%s\n%s\n" "#" "# Auto-generated generic secrets -- DO NOT EDIT." "#" >> "${GENERATED_SECRETS}"

# cloudflare api key
kubectl create secret generic cloudflare-api-key \
    --from-literal=api-key="${CF_API_KEY}" \
    --namespace cert-manager --dry-run=client -o json |
    kubeseal --format=yaml --cert="${PUB_CERT}" |
    # Remove null keys
    yq eval 'del(.metadata.creationTimestamp)' - |
    yq eval 'del(.spec.template.metadata.creationTimestamp)' - |
    # Format yaml file
    sed -e '1s/^/---\n/' |
    # Write secret
    tee -a "${GENERATED_SECRETS}" >/dev/null 2>&1

# github runner
kubectl create secret generic controller-manager \
    --from-literal=github_token="${GITHUB_RUNNER_ACCESS_TOKEN}" \
    --namespace actions-runner-system --dry-run=client -o json |
    kubeseal --format=yaml --cert="${PUB_CERT}" |
    # Remove null keys
    yq eval 'del(.metadata.creationTimestamp)' - |
    yq eval 'del(.spec.template.metadata.creationTimestamp)' - |
    # Format yaml file
    sed -e '1s/^/---\n/' |
    # Write secret
    tee -a "${GENERATED_SECRETS}" >/dev/null 2>&1

# uptimerobot heartbeat
kubectl create secret generic uptimerobot-heartbeat \
    --from-literal=url="${UPTIMEROBOT_HEARTBEAT_URL}" \
    --namespace monitoring --dry-run=client -o json |
    kubeseal --format=yaml --cert="${PUB_CERT}" |
    # Remove null keys
    yq eval 'del(.metadata.creationTimestamp)' - |
    yq eval 'del(.spec.template.metadata.creationTimestamp)' - |
    # Format yaml file
    sed -e '1s/^/---\n/' |
    # Write secret
    tee -a "${GENERATED_SECRETS}" >/dev/null 2>&1

# flux discord
kubectl create secret generic discord-webhook \
    --from-literal=address="${FLUX_DISCORD_WEBHOOK}" \
    --namespace flux-system --dry-run=client -o json |
    kubeseal --format=yaml --cert="${PUB_CERT}" |
    # Remove null keys
    yq eval 'del(.metadata.creationTimestamp)' - |
    yq eval 'del(.spec.template.metadata.creationTimestamp)' - |
    # Format yaml file
    sed -e '1s/^/---\n/' |
    # Write secret
    tee -a "${GENERATED_SECRETS}" >/dev/null 2>&1

# flux github
kubectl create secret generic webhook-token \
    --from-literal=token="${FLUX_GITHUB_TOKEN}" \
    --namespace flux-system --dry-run=client -o json |
    kubeseal --format=yaml --cert="${PUB_CERT}" |
    # Remove null keys
    yq eval 'del(.metadata.creationTimestamp)' - |
    yq eval 'del(.spec.template.metadata.creationTimestamp)' - |
    # Format yaml file
    sed -e '1s/^/---\n/' |
    # Write secret
    tee -a "${GENERATED_SECRETS}" >/dev/null 2>&1

# qbittorrent credentials
kubectl create secret generic qbittorrent \
    --from-literal=username="${QB_USERNAME}" \
    --from-literal=password="${QB_PASSWORD}" \
    --namespace media --dry-run=client -o json |
    kubeseal --format=yaml --cert="${PUB_CERT}" |
    # Remove null keys
    yq eval 'del(.metadata.creationTimestamp)' - |
    yq eval 'del(.spec.template.metadata.creationTimestamp)' - |
    # Format yaml file
    sed -e '1s/^/---\n/' |
    # Write secret
    tee -a "${GENERATED_SECRETS}" >/dev/null 2>&1

# gitea personal access token
kubectl create secret generic gitea-pat \
    --from-literal=token="${GITEA_PAT}" \
    --namespace velero --dry-run=client -o json |
    kubeseal --format=yaml --cert="${PUB_CERT}" |
    # Remove null keys
    yq eval 'del(.metadata.creationTimestamp)' - |
    yq eval 'del(.spec.template.metadata.creationTimestamp)' - |
    # Format yaml file
    sed -e '1s/^/---\n/' |
    # Write secret
    tee -a "${GENERATED_SECRETS}" >/dev/null 2>&1

# external-secrets credentials
# kubectl create secret generic aws-credentials \
#     --from-literal=id="${AWS_ACCESS_KEY_ID}" \
#     --from-literal=key="${AWS_SECRET_ACCESS_KEY}" \
#     --namespace kube-system --dry-run=client -o json |
#     kubeseal --format=yaml --cert="${PUB_CERT}" |
#     # Remove null keys
#     yq eval 'del(.metadata.creationTimestamp)' - |
#     yq eval 'del(.spec.template.metadata.creationTimestamp)' - |
#     # Format yaml file
#     sed -e '1s/^/---\n/' |
#     # Write secret
#     tee -a "${GENERATED_SECRETS}" >/dev/null 2>&1

# # sonarr episode prune - default namespace
# kubectl create secret generic sonarr-episode-prune \
#     --from-literal=api-key="${SONARR_APIKEY}" \
#     --namespace default --dry-run=client -o json |
#     kubeseal --format=yaml --cert="${PUB_CERT}" \
#         >>"${GENERATED_SECRETS}"
# echo "---" >>"${GENERATED_SECRETS}"

# # sonarr exporter
# kubectl create secret generic sonarr-exporter \
#     --from-literal=api-key="${SONARR_APIKEY}" \
#     --namespace monitoring --dry-run=client -o json |
#     kubeseal --format=yaml --cert="${PUB_CERT}" \
#         >>"${GENERATED_SECRETS}"
# echo "---" >>"${GENERATED_SECRETS}"

# # radarr exporter
# kubectl create secret generic radarr-exporter \
#     --from-literal=api-key="${RADARR_APIKEY}" \
#     --namespace monitoring --dry-run=client -o json |
#     kubeseal --format=yaml --cert="${PUB_CERT}" \
#         >>"${GENERATED_SECRETS}"
# echo "---" >>"${GENERATED_SECRETS}"

# # longhorn backup secret
# kubectl create secret generic longhorn-backup-secret \
#     --from-literal=AWS_ACCESS_KEY_ID="${MINIO_ACCESS_KEY}" \
#     --from-literal=AWS_SECRET_ACCESS_KEY="${MINIO_SECRET_KEY}" \
#     --from-literal=AWS_ENDPOINTS="http://192.168.1.39:9000" \
#     --namespace longhorn-system --dry-run=client -o json |
#     kubeseal --format=yaml --cert="${PUB_CERT}" \
#         >>"${GENERATED_SECRETS}"
# echo "---" >>"${GENERATED_SECRETS}"

# # nginx basic auth
# kubectl create secret generic nginx-basic-auth \
#     --from-literal=auth="${NGINX_BASIC_AUTH}" \
#     --namespace media --dry-run=client -o json |
#     kubeseal --format=yaml --cert="${PUB_CERT}" |
#     # Remove null keys
#     yq eval 'del(.metadata.creationTimestamp)' - |
#     yq eval 'del(.spec.template.metadata.creationTimestamp)' - |
#     # Format yaml file
#     sed -e '1s/^/---\n/' |
#     # Write secret
#     tee -a "${GENERATED_SECRETS}" >/dev/null 2>&1

# Remove empty new-lines
sed -i '/^[[:space:]]*$/d' "${GENERATED_SECRETS}"

# Validate Yaml
if ! yq eval "${GENERATED_SECRETS}" >/dev/null 2>&1; then
    echo "Errors in YAML"
    exit 1
fi

exit 0
