#!/usr/bin/env bash
set -eu

# shellcheck disable=SC2155
PROJECT_ROOT=$(git rev-parse --show-toplevel)
CLUSTER_ROOT="${PROJECT_ROOT}/cluster"
PUB_CERT="${PROJECT_ROOT}/sealed-secrets-public-cert.pem"
SECRETS_ENV="${PROJECT_ROOT}/.cluster-secrets.env"

# MacOS work-around for sed
if [ "$(uname)" == "Darwin" ]; then
    export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
fi

# Export environment variables
set -a
. "${SECRETS_ENV}"
set +a

# Check for exported environment variables
[ -n "${DOMAIN}" ] || {
    echo >&2 "* Error: Environment variables are not set... aborting."
    exit 1
}

# Generate Helm Secrets
txt_files=$(find "${CLUSTER_ROOT}" -type f -name "helm-values-secret.txt")

if [[ ( -n ${txt_files} ) ]];
then
    for txt_file in ${txt_files}; do
        # Get the absolute directory path of the helm-values-secret file
        # e.g. "/Users/devin/Code/homelab/home-cluster/cluster/media/flood"
        secret_path="$(dirname "$txt_file")"
        # Get the last folder name
        # e.g. "flood"
        secret_name=$(basename "${secret_path}")
        # Get the namespace (based on parent folder path of helm-values-secret.txt)
        # e.g. "media"
        namespace=$(basename "$(dirname "${secret_path}")")
        echo "[*] Generating helm secret '${secret_name}' in namespace '${namespace}'..."
        # Create secret
        envsubst < "$txt_file" |
            # Create the Kubernetes secret
            kubectl -n "${namespace}" create secret generic "${secret_name}-helm-values" \
                --from-file=/dev/stdin --dry-run=client -o json |
            # Seal the Kubernetes secret
            kubeseal --format=yaml --cert="${PUB_CERT}" |
            # Remove null keys
            yq e 'del(.metadata.creationTimestamp)' - |
            yq e 'del(.spec.template.metadata.creationTimestamp)' - |
            # Format yaml file
            sed \
                -e 's/stdin\:/values.yaml\:/g' \
                -e '/^[[:space:]]*$/d' \
                -e '1s/^/---\n/' |
            # Write secret
            tee "${secret_path}/sealed-secret.yaml" >/dev/null 2>&1
    done
fi
