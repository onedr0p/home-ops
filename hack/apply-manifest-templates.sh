#!/usr/bin/env bash

# Wire up the env and validations
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${__dir}/environment.sh"

#
# Apply the templates to the cluster
#
for file in "${CLUSTER_ROOT}"/_templates/*.tpl; do
    if output=$(envsubst < "$file"); then
        printf '%s' "$output" | kubectl apply -f -
    fi
done
