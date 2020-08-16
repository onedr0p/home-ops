#!/usr/bin/env bash
REPO_ROOT=$(git rev-parse --show-toplevel)
CLUSTER_ROOT="${REPO_ROOT}/deployments"

command -v kubectl >/dev/null 2>&1 || { echo >&2 "kubectl is not installed. Aborting."; exit 1; }
command -v envsubst >/dev/null 2>&1 || { echo >&2 "envsubst is not installed. Aborting."; exit 1; } 

set -a
. "${REPO_ROOT}/.cluster-secrets.env"
set +a

for file in "${CLUSTER_ROOT}"/_templates/*.tpl
do
  if output=$(envsubst < "$file"); then
    printf '%s' "$output" | kubectl apply -f -
  fi
done
