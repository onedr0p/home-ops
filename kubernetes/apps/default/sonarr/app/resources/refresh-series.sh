#!/usr/bin/env bash
set -euo pipefail

[[ "${sonarr_eventtype:-}" == "Grab" ]] || exit 0

readonly PLACEHOLDER_TITLE='\|(tba|tbd)\|'
shopt -s nocasematch
[[ "|${sonarr_release_episodetitles:-}|" =~ ${PLACEHOLDER_TITLE} ]] || exit 0

: "${SONARR__AUTH__APIKEY:?API key required}"
: "${SONARR__SERVER__PORT:?Server port required}"
: "${sonarr_series_id:?Series ID required}"

echo "Refreshing ${sonarr_series_title:-series ${sonarr_series_id}}: a grabbed episode is titled ${BASH_REMATCH[1]}"
curl -fsS --max-time 30 \
    --header "Content-Type: application/json" \
    --header "X-Api-Key: ${SONARR__AUTH__APIKEY}" \
    --request POST \
    --data "{\"name\":\"RefreshSeries\",\"seriesIds\":[${sonarr_series_id}]}" \
    "http://localhost:${SONARR__SERVER__PORT}/api/v5/command" >/dev/null
