#!/usr/bin/env bash

export REPO_ROOT
REPO_ROOT=$(git rev-parse --show-toplevel)

need() {
    which "$1" &>/dev/null || die "Binary '$1' is missing but required"
}

need "kubeseal"
need "kubectl"
need "sed"
need "envsubst"

if [ "$(uname)" == "Darwin" ]; then
  set -a
  . "${REPO_ROOT}/secrets/.secrets.env"
  set +a
else
  . "${REPO_ROOT}/secrets/.secrets.env"
fi

PUB_CERT="${REPO_ROOT}/secrets/pub-cert.pem"

# Helper function to generate secrets
kseal() {
  echo "------------------------------------"
  # Get the path and basename of the txt file
  # e.g. "deployments/default/pihole/pihole-helm-values"
  secret="$(dirname "$@")/$(basename -s .txt "$@")"
  echo "Secret: ${secret}"
  # Get the filename without extension
  # e.g. "pihole-helm-values"
  secret_name=$(basename "${secret}")
  echo "Secret Name: ${secret_name}"
  # Extract the Kubernetes namespace from the secret path
  # e.g. default
  namespace="$(echo "${secret}" | awk -F /deployments/ '{ print $2; }' | awk -F / '{ print $1; }')"
  echo "Namespace: ${namespace}"
  # Create secret and put it in the applications deployment folder
  # e.g. "deployments/default/pihole/pihole-helm-values.yaml"
  envsubst < "$@" | tee values.yaml \
    | \
  kubectl -n "${namespace}" create secret generic "${secret_name}" \
    --from-file=values.yaml --dry-run -o json \
    | \
  kubeseal --format=yaml --cert="$PUB_CERT" \
    > "${secret}.yaml"
  # Clean up temp file
  rm values.yaml
}

#
# Helm Secrets
#

kseal "${REPO_ROOT}/deployments/default/minio/minio-helm-values.txt"
kseal "${REPO_ROOT}/deployments/velero/velero/velero-helm-values.txt"

# kseal "${REPO_ROOT}/deployments/default/nzbget/nzbget-helm-values.txt"
# kseal "${REPO_ROOT}/deployments/default/radarr/radarr-helm-values.txt"
# kseal "${REPO_ROOT}/deployments/default/sonarr/sonarr-helm-values.txt"
# kseal "${REPO_ROOT}/deployments/default/qbittorrent/qbittorrent-helm-values.txt"
# kseal "${REPO_ROOT}/deployments/default/nzbhydra2/nzbhydra2-helm-values.txt"
# kseal "${REPO_ROOT}/deployments/default/jackett/jackett-helm-values.txt"
# kseal "${REPO_ROOT}/deployments/default/cloudflare-dyndns/cloudflare-dyndns-helm-values.txt"

#
# Generic Secrets
#

# NginX Basic Auth - default Namespace
kubectl create secret generic nginx-basic-auth \
  --from-literal=auth="$NGINX_BASIC_AUTH" \
  --namespace default --dry-run -o json \
  | \
kubeseal --format=yaml --cert="$PUB_CERT" \
    > "$REPO_ROOT"/deployments/kube-system/nginx-ingress/basic-auth-default.yaml

# NginX Basic Auth - kube-system Namespace
kubectl create secret generic nginx-basic-auth \
  --from-literal=auth="$NGINX_BASIC_AUTH" \
  --namespace kube-system --dry-run -o json \
  | \
kubeseal --format=yaml --cert="$PUB_CERT" \
    > "$REPO_ROOT"/deployments/kube-system/nginx-ingress/basic-auth-kube-system.yaml

# Cloudflare API Key - cert-manager Namespace
kubectl create secret generic cloudflare-api-key \
  --from-literal=api-key="$CF_API_KEY" \
  --namespace cert-manager --dry-run -o json \
  | \
kubeseal --format=yaml --cert="$PUB_CERT" \
    > "$REPO_ROOT"/deployments/cert-manager/cloudflare/cloudflare-api-key.yaml


