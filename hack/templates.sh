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

printenv | grep "TEST_SECRET"

echo "~~~~~~~~~~~~~~~~~~~~~~"
echo ">>> ${TEST_SECRET} <<<"
echo "~~~~~~~~~~~~~~~~~~~~~~"

echo "${REPO_ROOT}"

printenv

cat "${REPO_ROOT}/.cluster-secrets.sample.env" | grep "TEST_SECRET"

export TEST_TEST="blah"
echo "Will this subst, ples? \${TEST_TEST}" | envsubst

echo "Will this subst? \${TEST_SECRET}" | envsubst

# for file in "${CLUSTER_ROOT}"/_templates/*.tpl
# do
#   if output=$(envsubst -no-empty -no-unset -fail-fast < "$file"); then
#     printf '%s' "$output" | kubectl apply -f -
#   fi
# done