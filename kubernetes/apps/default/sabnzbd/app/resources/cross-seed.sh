#!/usr/bin/env bash
set -Eeuo pipefail

# User-defined variables
CROSS_SEED_HOST="${CROSS_SEED_HOST:?}"
CROSS_SEED_API_KEY="${CROSS_SEED_API_KEY:?}"
CROSS_SEED_SLEEP_INTERVAL="${CROSS_SEED_SLEEP_INTERVAL:?}"

# Function to search for cross-seed
search() {
    local status_code
    status_code=$(curl \
        --silent \
        --output /dev/null \
        --write-out "%{http_code}" \
        --request POST \
        --data-urlencode "path=${SAB_COMPLETE_DIR}" \
        --header "X-Api-Key: ${CROSS_SEED_API_KEY}" \
        "http://${CROSS_SEED_HOST}/api/webhook"
    )

    printf "cross-seed search returned with HTTP status code %s and path %s\n" "${status_code}" "${RELEASE_DIR}" >&2

    sleep "${CROSS_SEED_SLEEP_INTERVAL}"
}

main() {
    # Check if post-processing was successful
    if [[ "${SAB_PP_STATUS}" -ne 0 ]]; then
        printf "post-processing failed with sabnzbd status code %s\n" "${SAB_PP_STATUS}" >&2
        exit 1
    fi

    search
}

main "$@"
