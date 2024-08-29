#!/usr/bin/env bash
# shellcheck disable=SC2154

export PUSHOVER_USER_KEY="${PUSHOVER_USER_KEY:-required}"
export PUSHOVER_TOKEN="${PUSHOVER_TOKEN:-required}"
export PUSHOVER_DEVICE="${PUSHOVER_DEVICE:-}"
export PUSHOVER_PRIORITY="${PUSHOVER_PRIORITY:-"-2"}"
export PUSHOVER_SOUND="${PUSHOVER_SOUND:-}"

if [[ "${radarr_eventtype:-}" == "Test" ]]; then
    PUSHOVER_PRIORITY="1"
    printf -v PUSHOVER_TITLE "Test Notification"
    printf -v PUSHOVER_MESSAGE "Howdy this is a test notification from %s" "${radarr_instancename:-Sonarr}"
fi

if [[ "${radarr_eventtype:-}" == "Download" ]]; then
    printf -v PUSHOVER_TITLE "Movie %s" "$( [[ "${radarr_isupgrade}" == "True" ]] && echo "Upgraded" || echo "Downloaded" )"
    printf -v PUSHOVER_MESSAGE "<b>%s (%s)</b><small>\n%s</small><small>\n\n<b>Client:</b> %s</small><small>\n<b>Quality:</b> %s</small><small>\n<b>Size:</b> %s</small>" \
        "${radarr_movie_title}" \
        "${radarr_movie_year}" \
        "${radarr_movie_overview}" \
        "${radarr_download_client:-Unknown}" \
        "${radarr_moviefile_quality:-Unknown}" \
        "$(numfmt --to iec --format "%8.2f" "${radarr_release_size:-0}")"
    printf -v PUSHOVER_URL "%s/movie/%s" "${radarr_applicationurl:-localhost}" "${radarr_movie_tmdbid}"
    printf -v PUSHOVER_URL_TITLE "View movie in %s" "${radarr_instancename:-Radarr}"
fi

if [[ "${radarr_eventtype:-}" == "ManualInteractionRequired" ]]; then
    PUSHOVER_PRIORITY="1"
    printf -v PUSHOVER_TITLE "Movie import requires intervention"
    printf -v PUSHOVER_MESSAGE "<b>%s (%s)</b><small>\n<b>Client:</b> %s</small>" \
        "${radarr_movie_title}" \
        "${radarr_movie_year}" \
        "${radarr_download_client:-Unknown}"
    printf -v PUSHOVER_URL "%s/activity/queue" "${radarr_applicationurl:-localhost}"
    printf -v PUSHOVER_URL_TITLE "View queue in %s" "${radarr_instancename:-Radarr}"
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
    --request POST  \
    --header "Content-Type: application/json" \
    --data-binary "${notification}" \
    "https://api.pushover.net/1/messages.json" \
)

if [[ "${status_code}" -ne 200 ]] ; then
    printf "pushover notification failed to send with status code %s and payload: %s\n" "${status_code}" "$(echo "${notification}" | jq --compact-output)" >&2
    exit 1
fi

printf "pushover notification sent with status code %s and payload: %s\n" "${status_code}" "$(echo "${notification}" | jq --compact-output)"
