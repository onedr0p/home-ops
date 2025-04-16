#!/usr/bin/env bash
set -Eeuo pipefail

function notify() {
    if [[ "${RADARR_EVENT_TYPE}" == "Test" ]]; then
        printf -v PUSHOVER_TITLE "Test Notification"
        printf -v PUSHOVER_MESSAGE "Howdy this is a test notification"
        printf -v PUSHOVER_URL "%s" "${RADARR_APPLICATION_URL}"
        printf -v PUSHOVER_URL_TITLE "View Movies"
        printf -v PUSHOVER_PRIORITY "low"
    elif [[ "${RADARR_EVENT_TYPE}" == "ManualInteractionRequired" ]]; then
        printf -v PUSHOVER_TITLE "Movie Requires Manual Interaction"
        printf -v PUSHOVER_MESSAGE "<b>%s (%s)</b><small>\n<b>Client:</b> %s</small>" \
            "${RADARR_MOVIE_TITLE}" \
            "${RADARR_MOVIE_YEAR}" \
            "${RADARR_DOWNLOAD_CLIENT}"
        printf -v PUSHOVER_URL "%s/activity/queue" "${RADARR_APPLICATION_URL}"
        printf -v PUSHOVER_URL_TITLE "View Queue"
        printf -v PUSHOVER_PRIORITY "high"
    elif [[ "${RADARR_EVENT_TYPE}" == "Download" ]]; then
        printf -v PUSHOVER_TITLE "Movie Added"
        printf -v PUSHOVER_MESSAGE "<b>%s (%s)</b><small>\n%s</small><small>\n\n<b>Client:</b> %s</small>" \
            "${RADARR_MOVIE_TITLE}" \
            "${RADARR_MOVIE_YEAR}" \
            "${RADARR_MOVIE_OVERVIEW}" \
            "${RADARR_DOWNLOAD_CLIENT}"
        printf -v PUSHOVER_URL "%s/movie/%s" \
            "${RADARR_APPLICATION_URL}" \
            "${RADARR_MOVIE_TMDB_ID}"
        printf -v PUSHOVER_URL_TITLE "View Movie"
        printf -v PUSHOVER_PRIORITY "low"
    fi

    apprise -vv --title "${PUSHOVER_TITLE}" --body "${PUSHOVER_MESSAGE}" --input-format html \
        "${RADARR_PUSHOVER_URL}?url=${PUSHOVER_URL}&url_title=${PUSHOVER_URL_TITLE}&priority=${PUSHOVER_PRIORITY}&format=html"
}

function main() {
    notify
}

main "$@"
