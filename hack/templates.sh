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

# echo "~~~~~~~~~~~~~~~~~~~~~~"
# echo ">>> ${TEST_SECRET1} <<<"
# echo "~~~~~~~~~~~~~~~~~~~~~~"


# export TEST_TEST="blah"
# echo "Will this subst, ples? \${TEST_TEST}" | envsubst

# echo "Will this subst1? \${TEST_SECRET1}" | envsubst
# echo "Will this subst2? \${TEST_SECRET2}" | envsubst
# echo "Will this subst3? \${TEST_SECRET3}" | envsubst

# printenv

for file in "${CLUSTER_ROOT}"/_templates/*.tpl
do
  if output=$(envsubst -no-unset -no-empty -fail-fast < "$file"); then
    printf '%s' "$output" | kubectl apply -f -
  fi
done