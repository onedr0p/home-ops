#!/usr/bin/env bash
# shellcheck disable=SC2154

if [[ "${sonarr_eventtype:-}" == "Grab" ]]; then
    tba_count=$(curl -fsSL \
        --header "X-Api-Key: ${SONARR__AUTH__APIKEY}" \
        "http://localhost:${SONARR__SERVER__PORT}/api/v3/episode?seriesId=${sonarr_series_id}" \
            | jq --raw-output '[.[] | select((.title == "TBA") or (.title == "TBD"))] | length')

    if (( tba_count > 0 )); then
        echo "INFO: Refreshing series ${sonarr_series_id} due to TBA/TBD episodes found"
        curl -fsSL \
            --header "X-Api-Key: ${SONARR__AUTH__APIKEY}" \
            --header "Content-Type: application/json" \
            --data-binary '{"name": "RefreshSeries", "seriesId": '"${sonarr_series_id}"'}' \
            --request POST "http://localhost:${SONARR__SERVER__PORT}/api/v3/command" &> /dev/null
    fi
fi
