#!/usr/bin/env bash
set -Eeuo pipefail

# Remove the port from the IP address since Sonarr listens on port 80
SONARR_REMOTE_ADDR=${SONARR_REMOTE_ADDR%%:*}

function refresh() {
    if [[ "${SONARR_EVENT_TYPE}" == "Test" ]]; then
        echo "[DEBUG] test event received from ${SONARR_REMOTE_ADDR}, nothing to do ..."
    elif [[ "${SONARR_EVENT_TYPE}" == "Grab" ]]; then
        episodes=$(
            curl -fsSL --header "X-Api-Key: ${SONARR_API_KEY}" "http://${SONARR_REMOTE_ADDR}/api/v3/episode?seriesId=${SERIES_ID}" |
                jq --raw-output '[.[] | select((.title == "TBA") or (.title == "TBD"))] | length'
        )
        if ((episodes > 0)); then
            echo "[INFO] episode titles found with TBA/TBD titles, refreshing series ${SONARR_SERIES_TITLE} ..."
            curl -fsSL --request POST \
                --header "X-Api-Key: ${SONARR_API_KEY}" \
                --header "Content-Type: application/json" \
                --data-binary "$(jo name=RefreshSeries seriesId="${SERIES_ID}")" \
                "http://${SONARR_REMOTE_ADDR}/api/v3/command" &>/dev/null
        fi
    fi
}

function main() {
    refresh
}

main "$@"
