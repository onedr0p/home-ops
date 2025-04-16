#!/usr/bin/env bash
set -Eeuo pipefail

function notify() {
    if [[ "${SONARR_EVENT_TYPE}" == "Test" ]]; then
        printf -v PUSHOVER_TITLE "Test Notification"
        printf -v PUSHOVER_MESSAGE "Howdy this is a test notification"
        printf -v PUSHOVER_URL "%s" "${SONARR_APPLICATION_URL}"
        printf -v PUSHOVER_URL_TITLE "View Series"
        printf -v PUSHOVER_PRIORITY "low"
    elif [[ "${SONARR_EVENT_TYPE}" == "ManualInteractionRequired" ]]; then
        printf -v PUSHOVER_TITLE "Episode Requires Manual Interaction"
        printf -v PUSHOVER_MESSAGE "<b>%s</b><small>\n<b>Client:</b> %s</small>" \
            "${SONARR_SERIES_TITLE}" \
            "${SONARR_DOWNLOAD_CLIENT}"
        printf -v PUSHOVER_URL "%s/activity/queue" "${SONARR_APPLICATION_URL}"
        printf -v PUSHOVER_URL_TITLE "View Queue"
        printf -v PUSHOVER_PRIORITY "high"
    elif [[ "${SONARR_EVENT_TYPE}" == "Download" ]]; then
        printf -v PUSHOVER_TITLE "Episode Added"
        printf -v PUSHOVER_MESSAGE "<b>%s (S%02dE%02d)</b><small>\n%s</small><small>\n\n<b>Client:</b> %s</small><small>" \
            "${SONARR_SERIES_TITLE}" \
            "${SONARR_EPISODE_SEASON_NUMBER}" \
            "${SONARR_EPISODE_NUMBER}" \
            "${SONARR_EPISODE_TITLE}" \
            "${SONARR_DOWNLOAD_CLIENT}"
        printf -v PUSHOVER_URL "%s/series/%s" \
            "${SONARR_APPLICATION_URL}" \
            "${SONARR_SERIES_TITLE_SLUG}"
        printf -v PUSHOVER_URL_TITLE "View Series"
        printf -v PUSHOVER_PRIORITY "low"
    fi

    apprise -vv --title "${PUSHOVER_TITLE}" --body "${PUSHOVER_MESSAGE}" --input-format html \
        "${SONARR_PUSHOVER_URL}?url=${PUSHOVER_URL}&url_title=${PUSHOVER_URL_TITLE}&priority=${PUSHOVER_PRIORITY}&format=html"
}

function main() {
    notify
}

main "$@"
