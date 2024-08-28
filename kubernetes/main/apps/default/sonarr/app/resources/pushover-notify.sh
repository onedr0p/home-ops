#!/usr/bin/env bash
# shellcheck disable=SC2154

export PUSHOVER_USER_KEY="${PUSHOVER_USER_KEY:-required}"
export PUSHOVER_TOKEN="${PUSHOVER_TOKEN:-required}"
export PUSHOVER_DEVICE="${PUSHOVER_DEVICE:-}"
export PUSHOVER_PRIORITY="${PUSHOVER_PRIORITY:-"-2"}"
export PUSHOVER_SOUND="${PUSHOVER_SOUND:-}"

if [[ "${sonarr_eventtype:-}" == "Test" ]]; then
    PUSHOVER_PRIORITY="1"
    printf -v PUSHOVER_TITLE "Test Notification"
    printf -v PUSHOVER_MESSAGE "Howdy this is a test notification from %s" "${sonarr_instancename:-Sonarr}"
fi

if [[ "${sonarr_eventtype:-}" == "Download" ]]; then
    printf -v PUSHOVER_TITLE "Episode %s" "$( [[ "${sonarr_isupgrade}" == "True" ]] && echo "Upgraded" || echo "Downloaded" )"
    printf -v PUSHOVER_MESSAGE "<b>%s (S%02dE%02d)</b><small>\n%s</small><small>\n\n<b>Quality:</b> %s</small><small>\n<b>Client:</b> %s</small>" \
        "${sonarr_series_title}" \
        "${sonarr_episodefile_seasonnumber}" \
        "${sonarr_episodefile_episodenumbers}" \
        "${sonarr_episodefile_episodetitles}" \
        "${sonarr_episodefile_quality:-Unknown}" \
        "${sonarr_download_client:-Unknown}"
    printf -v PUSHOVER_URL "%s/series/%s" "${sonarr_applicationurl:-localhost}" "${sonarr_series_titleslug}"
    printf -v PUSHOVER_URL_TITLE "View series in %s" "${sonarr_instancename:-Sonarr}"
fi

if [[ "${sonarr_eventtype:-}" == "ManualInteractionRequired" ]]; then
    PUSHOVER_PRIORITY="1"
    printf -v PUSHOVER_TITLE "Episode import requires intervention"
    printf -v PUSHOVER_MESSAGE "<b>%s</b><small>\n<b>Client:</b> %s</small>" \
        "${sonarr_series_title}" \
        "${sonarr_download_client:-Unknown}"
    printf -v PUSHOVER_URL "%s/activity/queue" "${sonarr_applicationurl:-localhost}"
    printf -v PUSHOVER_URL_TITLE "View queue in %s" "${sonarr_instancename:-Sonarr}"
fi

notification=$(jq --null-input \
    --arg token "${PUSHOVER_TOKEN}" \
    --arg user "${PUSHOVER_USER_KEY}" \
    --arg title "${PUSHOVER_TITLE}" \
    --arg message "${PUSHOVER_MESSAGE}" \
    --arg url "${PUSHOVER_URL}" \
    --arg url_title "${PUSHOVER_URL_TITLE}" \
    --arg priority "${PUSHOVER_PRIORITY}" \
    --arg sound "${PUSHOVER_SOUND}" \
    --arg device "${PUSHOVER_DEVICE}" \
    --arg html "1" \
    '{token: $token, user: $user, title: $title, message: $message, url: $url, url_title: $url_title, priority: $priority, sound: $sound, device: $device, html: $html}' \
)

status_code=$(curl \
    --silent \
    --write-out "%{http_code}" \
    --output /dev/null \
    --request POST \
    --header "Content-Type: application/json" \
    --data-binary "${notification}" \
    "https://api.pushover.net/1/messages.json" \
)

if [[ "${status_code}" -ne 200 ]] ; then
    printf "pushover notification failed to send with status code %s and payload: %s\n" "${status_code}" "$(echo "${notification}" | jq --compact-output)" >&2
    exit 1
fi

printf "pushover notification sent with status code %s and payload: %s\n" "${status_code}" "$(echo "${notification}" | jq --compact-output)"
