#!/usr/bin/env bash
shopt -s globstar

# shellcheck disable=SC2155
export REPO_ROOT=$(git rev-parse --show-toplevel)
export CLUSTER_ROOT="${REPO_ROOT}/cluster"
export PUB_CERT="${REPO_ROOT}/sealed-secrets-public-cert.pem"
export SECRETS_ENV="${REPO_ROOT}/.cluster-secrets.env"

# MacOS work-around for sed
if [ "$(uname)" == "Darwin" ]; then
    # Check if gnu-sed exists
    command -v gsed >/dev/null 2>&1 || {
        echo >&2 "gsed is not installed. Aborting."
        exit 1
    }
    # Export path w/ gnu-sec
    export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
fi

# Ensure these cli utils exist
command -v kubectl >/dev/null 2>&1 || {
    echo >&2 "kubectl is not installed. Aborting."
    exit 1
}
command -v envsubst >/dev/null 2>&1 || {
    echo >&2 "envsubst is not installed. Aborting."
    exit 1
}
command -v kubeseal >/dev/null 2>&1 || {
    echo >&2 "kubeseal is not installed. Aborting."
    exit 1
}
command -v yq >/dev/null 2>&1 || {
    echo >&2 "yq is not installed. Aborting."
    exit 1
}

# Check secrets env file exists
[ -f "${SECRETS_ENV}" ] || {
    echo >&2 "Secret enviroment file doesn't exist. Aborting."
    exit 1
}
# Check secrets env file is text (git-crypt has decrypted it)
file "${SECRETS_ENV}" | grep "ASCII text" >/dev/null 2>&1 || {
    echo >&2 "Secret enviroment file isn't a text file. Aborting."
    exit 1
}

# Export environment variables
set -a
. "${SECRETS_ENV}"
set +a

# Check for environment variables
[ -n "${DOMAIN}" ] || {
    echo >&2 "Environment variables are not set. Aborting."
    exit 1
}
