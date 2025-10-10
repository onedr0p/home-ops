#!/usr/bin/env bash
# shellcheck disable=SC2154
set -euo pipefail

[[ "${sonarr_eventtype}" == "Grab" ]] || exit 0

curl_cmd=("curl" "-fsSL" "--header" "X-Api-Key: ${SONARR__AUTH__APIKEY}")
sonarr_api_url="http://localhost:${SONARR__SERVER__PORT}/api/v3"

episodes=$("${curl_cmd[@]}" "${sonarr_api_url}/episode?seriesId=${sonarr_series_id}" | jq -r '
    [.[] | select((.title // "" | ascii_downcase) | test("^(tba|tbd)$"))] | length
')

if (( episodes > 0 )); then
    echo "Refreshing series ${sonarr_series_id} due to ${episodes} episodes with TBA/TBD names"
    "${curl_cmd[@]}" \
        --request POST \
        --header "Content-Type: application/json" \
        --data-binary '{"name": "RefreshSeries", "seriesId": '"${sonarr_series_id}"'}' \
        "${sonarr_api_url}/command" &>/dev/null
fi
