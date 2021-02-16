#!/usr/bin/env bash
set -eu

#
# Pre-requisite: run `op signin <op-domain>` once
#
# Usage: ./op.sh <op-domain> <op-email> <op-vault>
#

if [[ $# -lt 3 ]] ; then
    echo "Usage: ./op.sh <op-domain> <op-email> <op-vault>"
    echo "Error expected 3 arguments"
    exit 1
fi

OP_DOMAIN="${1}"
OP_EMAIL="${2}"
OP_VAULT="${3}"

# set op session variable
OP_SESSION="OP_SESSION_${OP_DOMAIN}"

# require op
command -v op >/dev/null 2>&1 || {
    echo >&2 "op is not installed. Aborting."
    exit 1
}

# require jq
command -v jq >/dev/null 2>&1 || {
    echo >&2 "jq is not installed. Aborting."
    exit 1
}

# log into 1password
if [ -v "${OP_SESSION}" ]; then
    echo "OP_SESSION_${OP_DOMAIN} variable exists"
    if ! op get user "${OP_EMAIL}" --session "${!OP_SESSION}" >/dev/null 2>&1; then
        echo "OP_SESSION_${OP_DOMAIN} token invalid"
        OP_SESSION=$(op signin "${OP_DOMAIN}" --raw)
    else
        echo "OP_SESSION_${OP_DOMAIN} token valid"
        OP_SESSION="${!OP_SESSION}"
    fi
else
    echo "OP_SESSION_${OP_DOMAIN} variable does not exist"
    OP_SESSION=$(op signin "${OP_DOMAIN}" --raw)
fi

# set session token
declare "OP_SESSION_${OP_DOMAIN}=${OP_SESSION}"

secrets=$(op list items --vault "${OP_VAULT}" --categories "Password" | op get item - --fields title,password | jq -s .)

echo "${secrets}"
