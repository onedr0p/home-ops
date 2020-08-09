#!/usr/bin/env bash

# Get Absolute Path of the base repo
export REPO_ROOT=$(git rev-parse --show-toplevel)
# Get Absolute Path of where Flux looks for manifests
export CLUSTER_ROOT="${REPO_ROOT}/deployments"

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

#
# Kubernetes Manifests w/ Secrets
#

for file in "${CLUSTER_ROOT}"/_templates/*.tpl
do
  # Get the path and basename of the txt file
  secret_path="$(dirname "$file")/$(basename -s .tpl "$file")"
  # Get the filename without extension
  secret_name=$(basename "${secret_path}")
  echo "Applying manifest ${secret_name} to cluster..."
  # Apply this manifest to our cluster
  if output=$(envsubst < "$file"); then
    printf '%s' "$output" | kubectl apply -f -
  fi
done