#!/usr/bin/env bash

# Wire up the env and validations
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${__dir}/environment.sh"

sed 's/=.*/=""/' "${REPO_ROOT}/.cluster-secrets.env" >"${REPO_ROOT}/.cluster-secrets.sample.env"
cat "${REPO_ROOT}/.cluster-secrets.sample.env"
