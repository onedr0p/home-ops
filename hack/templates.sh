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

printenv | grep "TEST_SECRET"

echo "~~~~~~~~~~~~~~~~~~~~~~"
echo ">>> ${TEST_SECRET} <<<"
echo "~~~~~~~~~~~~~~~~~~~~~~"

echo "${REPO_ROOT}"

cat "${REPO_ROOT}/.cluster-secrets.env" | grep "TEST_SECRET"

echo "Will this subst? \${TEST_SECRET}" | envsubst -no-empty -no-unset -fail-fast

# for file in "${CLUSTER_ROOT}"/_templates/*.tpl
# do
#   if output=$(envsubst -no-empty -no-unset -fail-fast < "$file"); then
#     printf '%s' "$output" | kubectl apply -f -
#   fi
# done