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

# Setup base API URL
readonly SONARR_API_URL="http://localhost:${SONARR__SERVER__PORT}/api/v3"

# Wrapper for API calls
api_call() {
    curl -fsSL --max-time 30 \
        --header "Content-Type: application/json" \
        --header "X-Api-Key: ${SONARR__AUTH__APIKEY}" \
        "$@"
}

# Check for episodes with TBA/TBD titles
episodes=$(api_call "${SONARR_API_URL}/episode?seriesId=${SERIES_ID}" | \
    jq '[.[] | select(.title // "" | ascii_downcase | test("^(tba|tbd)$"))] | length')

# Refresh series if any TBA/TBD episodes found
if (( episodes > 0 )); then
    echo "Refreshing series ${SERIES_ID} (${episodes} TBA/TBD episodes found)"
    api_call -X POST --data-binary "{\"name\": \"RefreshSeries\", \"seriesId\": ${SERIES_ID}}" \
        "${SONARR_API_URL}/command" >/dev/null
fi
