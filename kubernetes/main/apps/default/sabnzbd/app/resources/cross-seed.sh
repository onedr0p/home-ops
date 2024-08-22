#!/usr/bin/env bash

export CROSS_SEED_HOST=${CROSS_SEED_HOST:-cross-seed.default.svc.cluster.local}
export CROSS_SEED_PORT=${CROSS_SEED_PORT:-80}

SEARCH_PATH=$1

log_message() {
    local log_type="$1"
    local message="$2"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "${timestamp} [${log_type}] ${message}"
}

cross_seed_request() {
    local endpoint="$1"
    local data="$2"
    local headers=(-X POST "http://${CROSS_SEED_HOST}:${CROSS_SEED_PORT}/api/${endpoint}" --data-urlencode "${data}")
    if [[ -n "${CROSS_SEED_API_KEY}" ]]; then
        headers+=(-H "X-Api-Key: ${CROSS_SEED_API_KEY}")
    fi
    response=$(curl --silent --output /dev/null --write-out "%{http_code}" "${headers[@]}")
    echo "${response}"
}

cross_seed_resp=$(cross_seed_request "webhook" "path=${SEARCH_PATH}")

if [[ "${cross_seed_resp}" == "204" ]]; then
    log_message "INFO" "Process completed successfully."
    sleep 30
else
    log_message "ERROR" "Process failed with API response: ${cross_seed_resp}"
    exit 1
fi
