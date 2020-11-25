#!/usr/bin/env bash
#
# Usage: generate-helm-secret.sh deployments/default/gitea/gitea.txt
# or
# task generate-helm-secret "TXT_FILE=deployments/default/gitea/gitea.txt"
#

# Wire up the env and cli validations
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${__dir}/environment.sh"

# Input file is .txt file of yaml containing environment variable keys
TXT_FILE="${1}"

# Validate input file is txt
if [[ $TXT_FILE != *.txt ]]; then
    echo "[ERROR] Input file '${TXT_FILE}' is not a .txt file. Aborting."
    exit 1
fi

# Validate input file is valid yaml
if ! yq validate "${TXT_FILE}" >/dev/null 2>&1; then
    echo "[ERROR] YAML validation errors in '${TXT_FILE}'. Aborting."
    exit 1
fi

# Set the path and basename of the txt file | e.g. "./deployments/default/gitea/gitea"
template_base="$(dirname "${TXT_FILE}")/$(basename -s .txt "${TXT_FILE}")"
# Set the final path and filename of the secret | e.g. "./deployments/default/gitea/gitea-helm-values.yaml"
secret_filename="${template_base}-helm-values.yaml"
# Set the name without extension | e.g. "gitea-helm-values"
secret_name=$(basename -s .yaml "${secret_filename}")
# Set the relative path of deployment | e.g. "deployments/default/gitea/gitea.txt"
deployment=${TXT_FILE#"${CLUSTER_ROOT}"}
# Set the namespace (based on folder path of manifest) | e.g. "default"
namespace=$(echo "${deployment}" | awk -F/ '{print $2}')

echo "[DEBUG] Generating sealed-secret for '${TXT_FILE}' into '${secret_filename}'"

# Replace environment variables
envsubst <"$TXT_FILE" |
    # Create the Kubernetes secret
    kubectl -n "${namespace}" create secret generic "${secret_name}" \
        --from-file=/dev/stdin --dry-run=client -o json |
    # Seal the Kubernetes secret
    kubeseal --format=yaml --cert="${PUB_CERT}" |
    # Remove null keys
    yq d - "metadata.creationTimestamp" |
    yq d - "spec.template.metadata.creationTimestamp" |
    # Format yaml file
    sed \
        -e 's/stdin\:/values.yaml\:/g' \
        -e '/^[[:space:]]*$/d' \
        -e '1s/^/---\n/' |
    # Write secret
    tee "${secret_filename}" >/dev/null 2>&1

# Validate w/ kubeseal
if ! kubeseal --validate --controller-name=sealed-secrets <"${secret_filename}" >/dev/null 2>&1; then
    echo "[ERROR] The controller will not be able to decrypt this secret ${secret_filename}. Aborting."
    exit 1
fi

# Validate w/ yq
if ! yq validate "${secret_filename}" >/dev/null 2>&1; then
    echo "[ERROR] YAML validation errors in ${secret_filename}. Aborting."
    exit 1
fi

exit 0
