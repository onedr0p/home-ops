#!/usr/bin/env bash

export CROSS_SEED_HOST="${CROSS_SEED_HOST:-required}"
export CROSS_SEED_PORT="${CROSS_SEED_PORT:-required}"
export CROSS_SEED_API_KEY="${CROSS_SEED_API_KEY:-required}"
export CROSS_SEED_SLEEP_INTERVAL="${CROSS_SEED_SLEEP_INTERVAL:-30}"

SEARCH_PATH=$1

# Update permissions on the search path
chmod -R 750 "${SEARCH_PATH}"

# Search for cross-seed
status_code=$(curl \
    --silent \
    --output /dev/null \
    --write-out "%{http_code}" \
    --request POST \
    --data-urlencode "path=${SEARCH_PATH}" \
    --header "X-Api-Key: ${CROSS_SEED_API_KEY}" \
    "http://${CROSS_SEED_HOST}:${CROSS_SEED_PORT}/api/webhook"
)

if [[ "${status_code}" -ne 204 ]]; then
    printf "cross-seed search failed with status code %s and path %s\n" "${status_code}" "${SEARCH_PATH}"
    exit 1
fi

printf "cross-seed search success with status code %s and path %s\n" "${status_code}" "${SEARCH_PATH}"

sleep "${CROSS_SEED_SLEEP_INTERVAL}"
