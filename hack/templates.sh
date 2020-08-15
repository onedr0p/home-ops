#!/usr/bin/env bash
REPO_ROOT=$(git rev-parse --show-toplevel)
CLUSTER_ROOT="${REPO_ROOT}/deployments"

need() {
  if ! [ -x "$(command -v $1)" ]; then
    echo "Error: Unable to find binary $1"
    exit 1
  fi
}

# Verify we have dependencies
need "kubectl"
need "envsubst"

# Work-arounds for MacOS
if [ "$(uname)" == "Darwin" ]; then
  # Source secrets.env
  set -a
  . "${REPO_ROOT}/.cluster-secrets.env"
  set +a
else
  . "${REPO_ROOT}/.cluster-secrets.env"
fi

for file in "${CLUSTER_ROOT}"/_templates/*.tpl
do
  if output=$(envsubst < "$file"); then
    printf '%s' "$output" | kubectl apply -f -
  fi
done