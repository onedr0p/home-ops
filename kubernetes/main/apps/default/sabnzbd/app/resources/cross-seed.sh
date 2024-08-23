#!/usr/bin/env bash

export CROSS_SEED_HOST=${CROSS_SEED_HOST:-cross-seed.default.svc.cluster.local}
export CROSS_SEED_PORT=${CROSS_SEED_PORT:-80}
export CROSS_SEED_API_KEY=${CROSS_SEED_API_KEY:-unset}
export CROSS_SEED_SLEEP_INTERVAL=${CROSS_SEED_SLEEP_INTERVAL:-30}

SEARCH_PATH=$1

# Update permissions on the search path
chmod -R 750 "${SEARCH_PATH}"

# Search for cross-seed
response=$(curl \
    --silent \
    --output /dev/null \
    --write-out "%{http_code}" \
    --request POST \
    --data-urlencode "path=${SEARCH_PATH}" \
    --header "X-Api-Key: ${CROSS_SEED_API_KEY}" \
    "http://${CROSS_SEED_HOST}:${CROSS_SEED_PORT}/api/webhook"
)

if [[ "${response}" != "204" ]]; then
    printf "Failed to search cross-seed for '%s'\n" "${SEARCH_PATH}"
    exit 1
fi

printf "Successfully searched cross-seed for '%s'\n" "${SEARCH_PATH}"

sleep "${CROSS_SEED_SLEEP_INTERVAL}"
