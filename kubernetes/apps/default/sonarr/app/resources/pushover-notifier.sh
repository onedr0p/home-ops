#!/usr/bin/env bash
# shellcheck disable=SC2154
set -euo pipefail

# User defined variables for pushover
PUSHOVER_USER_KEY="${PUSHOVER_USER_KEY:-required}"
PUSHOVER_TOKEN="${PUSHOVER_TOKEN:-required}"
PUSHOVER_PRIORITY="${PUSHOVER_PRIORITY:-"-2"}"

if [[ "${sonarr_eventtype:-}" == "Test" ]]; then
    PUSHOVER_PRIORITY="1"
    printf -v PUSHOVER_TITLE \
        "Test Notification"
    printf -v PUSHOVER_MESSAGE \
        "Howdy this is a test notification from %s" \
            "${sonarr_instancename:-Sonarr}"
    printf -v PUSHOVER_URL \
        "%s" \
            "${sonarr_applicationurl:-localhost}"
    printf -v PUSHOVER_URL_TITLE \
        "Open %s" \
            "${sonarr_instancename:-Sonarr}"
fi

if [[ "${sonarr_eventtype:-}" == "Download" ]]; then
    printf -v PUSHOVER_TITLE \
        "Episode %s" \
            "$( [[ "${sonarr_isupgrade}" == "True" ]] && echo "Upgraded" || echo "Downloaded" )"
    printf -v PUSHOVER_MESSAGE \
        "<b>%s (S%02dE%02d)</b><small>\n%s</small><small>\n\n<b>Quality:</b> %s</small><small>\n<b>Client:</b> %s</small>" \
            "${sonarr_series_title}" \
            "${sonarr_episodefile_seasonnumber}" \
            "${sonarr_episodefile_episodenumbers}" \
            "${sonarr_episodefile_episodetitles}" \
            "${sonarr_episodefile_quality:-Unknown}" \
            "${sonarr_download_client:-Unknown}"
    printf -v PUSHOVER_URL \
        "%s/series/%s" \
            "${sonarr_applicationurl:-localhost}" \
            "${sonarr_series_titleslug}"
    printf -v PUSHOVER_URL_TITLE \
        "View series in %s" \
            "${sonarr_instancename:-Sonarr}"
fi

if [[ "${sonarr_eventtype:-}" == "ManualInteractionRequired" ]]; then
    PUSHOVER_PRIORITY="1"
    printf -v PUSHOVER_TITLE \
        "Episode import requires intervention"
    printf -v PUSHOVER_MESSAGE \
        "<b>%s</b><small>\n<b>Client:</b> %s</small>" \
            "${sonarr_series_title}" \
            "${sonarr_download_client:-Unknown}"
    printf -v PUSHOVER_URL \
        "%s/activity/queue" \
            "${sonarr_applicationurl:-localhost}"
    printf -v PUSHOVER_URL_TITLE \
        "View queue in %s" \
            "${sonarr_instancename:-Sonarr}"
fi

json_data=$(jo \
    token="${PUSHOVER_TOKEN}" \
    user="${PUSHOVER_USER_KEY}" \
    title="${PUSHOVER_TITLE}" \
    message="${PUSHOVER_MESSAGE}" \
    url="${PUSHOVER_URL}" \
    url_title="${PUSHOVER_URL_TITLE}" \
    priority="${PUSHOVER_PRIORITY}" \
    html="1"
)

status_code=$(curl \
    --silent \
    --write-out "%{http_code}" \
    --output /dev/null \
    --request POST \
    --header "Content-Type: application/json" \
    --data-binary "${json_data}" \
    "https://api.pushover.net/1/messages.json" \
)

printf "pushover notification returned with HTTP status code %s and payload: %s\n" \
    "${status_code}" \
    "$(echo "${json_data}" | jq --compact-output)" >&2
