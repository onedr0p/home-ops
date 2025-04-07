#!/usr/bin/env bash
set -Eeuo pipefail

function notify() {
    if [[ "${RADARR_EVENT_TYPE}" == "Test" ]]; then
        printf -v PUSHOVER_TITLE "Test Notification"
        printf -v PUSHOVER_MESSAGE "Howdy this is a test notification from <b>%s</b>" "${RADARR_INSTANCE_NAME}"
        printf -v PUSHOVER_URL "%s" "${RADARR_APPLICATION_URL}"
        printf -v PUSHOVER_URL_TITLE "Open %s" "${RADARR_INSTANCE_NAME}"
        printf -v PUSHOVER_PRIORITY "%s" "low"
    elif [[ "${RADARR_EVENT_TYPE}" == "ManualInteractionRequired" ]]; then
        printf -v PUSHOVER_TITLE "%s Import Requires Manual Interaction" "Movie"
        printf -v PUSHOVER_MESSAGE "<b>%s (%s)</b><small>\n<b>Client:</b> %s</small>" \
            "${RADARR_MOVIE_TITLE}" \
            "${RADARR_MOVIE_YEAR}" \
            "${RADARR_DOWNLOAD_CLIENT}"
        printf -v PUSHOVER_URL "%s/activity/queue" "${RADARR_APPLICATION_URL}"
        printf -v PUSHOVER_URL_TITLE "View queue in %s" "${RADARR_INSTANCE_NAME}"
        printf -v PUSHOVER_PRIORITY "%s" "high"
    elif [[ "${RADARR_EVENT_TYPE}" == "Download" ]]; then
        printf -v PUSHOVER_TITLE "Movie %s" "Imported"
        printf -v PUSHOVER_MESSAGE "<b>%s (%s)</b><small>\n%s</small><small>\n\n<b>Client:</b> %s</small>" \
            "${RADARR_MOVIE_TITLE}" \
            "${RADARR_MOVIE_YEAR}" \
            "${RADARR_MOVIE_OVERVIEW}" \
            "${RADARR_DOWNLOAD_CLIENT}"
        printf -v PUSHOVER_URL "%s/movie/%s" \
            "${RADARR_APPLICATION_URL}" \
            "${RADARR_MOVIE_TMDB_ID}"
        printf -v PUSHOVER_URL_TITLE "View movie in %s" "${RADARR_INSTANCE_NAME}"
        printf -v PUSHOVER_PRIORITY "%s" "low"
    fi

    apprise -vv --title "${PUSHOVER_TITLE}" --body "${PUSHOVER_MESSAGE}" \
        "${RADARR_PUSHOVER_URL}?url=${PUSHOVER_URL}&url_title=${PUSHOVER_URL_TITLE}&priority=${PUSHOVER_PRIORITY}&format=markdown"
}

function main() {
    notify
}

main "$@"
