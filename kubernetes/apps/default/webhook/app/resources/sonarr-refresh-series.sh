#!/usr/bin/env bash
set -Eeuo pipefail

SONARR_URL=${1:?}
SONARR_API_KEY=${2:?}
PAYLOAD=${3:?}

echo "[DEBUG] Payload: ${PAYLOAD}"

function _jq() {
    jq --raw-output "${1:?}" <<< "${PAYLOAD}"
}

function refresh() {
    local event="$(_jq '.eventType')"
    local series_id="$(_jq '.series.id')"

    if [[ "${event}" == "Test" ]]; then
        echo "Test event received, nothing to do ..."
    fi

    if [[ "${event}" == "Grab" ]]; then
        episodes=$(\
            curl -fsSL --header "X-Api-Key: ${SONARR_API_KEY}" "${SONARR_URL}/api/v3/episode?seriesId=${series_id}" \
                | jq --raw-output '[.[] | select((.title == "TBA") or (.title == "TBD"))] | length' \
        )

        if (( episodes > 0 )); then
            echo "TBA/TBD episode titles found, refreshing series ${series_id} ..."
            curl -fsSL --header "X-Api-Key: ${SONARR_API_KEY}" \
                --request POST \
                --header "Content-Type: application/json" \
                --data-binary '{"name": "RefreshSeries", "seriesId": '"${series_id}"'}' \
                "${SONARR_URL}/api/v3/command" &>/dev/null
        fi
    fi
}

function main() {
    refresh
}

main "$@"
