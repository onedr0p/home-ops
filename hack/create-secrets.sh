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
    printf "%s\n%s\n%s\n" "#" "# Auto-generated secrets -- DO NOT EDIT." "#" >> "${GENERATED_SECRETS}"

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

# Remove empty new-lines
sed -i '/^[[:space:]]*$/d' "${GENERATED_SECRETS}"

# Validate Yaml
if ! yq eval "${GENERATED_SECRETS}" >/dev/null 2>&1; then
    echo "Errors in YAML"
    exit 1
fi

exit 0
