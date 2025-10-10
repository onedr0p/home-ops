#!/usr/bin/env bash
# shellcheck disable=SC2154
set -euo pipefail

[[ "${sonarr_eventtype:-}" == "Grab" ]] || exit 0

CURL_CMD=("curl" "-fsSL" "--header" "X-Api-Key: ${SONARR__AUTH__APIKEY:-}")
SONARR_API_URL="http://localhost:${SONARR__SERVER__PORT:-}/api/v3"

episodes=$("${CURL_CMD[@]}" "${SONARR_API_URL}/episode?seriesId=${sonarr_series_id:-}" | jq -r '
    [.[] | select((.title // "" | ascii_downcase) | test("^(tba|tbd)$"))] | length
')

if (( episodes > 0 )); then
    echo "Refreshing series ${sonarr_series_id:-} due to ${episodes} episodes with TBA/TBD names"
    "${CURL_CMD[@]}" \
        --request POST \
        --header "Content-Type: application/json" \
        --data-binary '{"name": "RefreshSeries", "seriesId": '"${sonarr_series_id:-}"'}' \
        "${SONARR_API_URL}/command" &>/dev/null
fi
