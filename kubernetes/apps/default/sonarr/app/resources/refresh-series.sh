#!/usr/bin/env bash
set -euo pipefail

# Incoming environment variables
EVENT_TYPE="${sonarr_eventtype:-}"
SERIES_ID="${sonarr_series_id:-}"

# Only proceed for "Grab" events with valid series ID
[[ "${EVENT_TYPE}" == "Grab" && -n "${SERIES_ID}" ]] || exit 0

# Required environment variables
: "${SONARR__AUTH__APIKEY:?API key required}"
: "${SONARR__SERVER__PORT:?Server port required}"

# Setup curl command and base API URL
readonly CURL_CMD=("curl" "-fsSL" "--max-time" "30" "--header" "X-Api-Key: ${SONARR__AUTH__APIKEY}")
readonly SONARR_API_URL="http://localhost:${SONARR__SERVER__PORT}/api/v3"

# Check for episodes with TBA/TBD titles and refresh series if found
episodes=$("${CURL_CMD[@]}" "${SONARR_API_URL}/episode?seriesId=${SERIES_ID}" | \
    jq -r '[.[] | select((.title // "" | ascii_downcase) | test("^(tba|tbd)$"))] | length')

# If any episodes with TBA/TBD titles are found, refresh the series
if (( episodes > 0 )); then
    echo "Refreshing series ${SERIES_ID} due to ${episodes} episodes with TBA/TBD names"
    "${CURL_CMD[@]}" \
        --request POST \
        --header "Content-Type: application/json" \
        --data-binary "{\"name\": \"RefreshSeries\", \"seriesId\": ${SERIES_ID}}" \
        "${SONARR_API_URL}/command" >/dev/null
fi
