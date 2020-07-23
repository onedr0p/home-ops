#!/usr/bin/env bash

shopt -s globstar

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
need "kubeseal"
need "kubectl"
need "sed"
need "envsubst"
need "yq"

# Work-arounds for MacOS
if [ "$(uname)" == "Darwin" ]; then
  # brew install gnu-sed
  need "gsed"
  # use sed as alias to gsed
  export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
  # Source secrets.env
  set -a
  . "${REPO_ROOT}/secrets/.secrets.env"
  set +a
else
  . "${REPO_ROOT}/secrets/.secrets.env"
fi

#
# Kubernetes Manifests w/ Secrets
#

for file in "${REPO_ROOT}"/secrets/manifest-templates/*.txt
do
  # Get the path and basename of the txt file
  secret_path="$(dirname "$file")/$(basename -s .txt "$file")"
  # Get the filename without extension
  secret_name=$(basename "${secret_path}")
  echo "  Applying manifest ${secret_name} to cluster..."
  # Apply this manifest to our cluster
  if output=$(envsubst < "$file"); then
    printf '%s' "$output" | kubectl apply -f -
  fi
done