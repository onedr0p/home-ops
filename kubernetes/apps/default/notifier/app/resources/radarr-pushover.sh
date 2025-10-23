#!/usr/bin/env bash
set -euo pipefail

# Incoming arguments
PAYLOAD=${1:-}

# Required environment variables
: "${APPRISE_RADARR_PUSHOVER_URL:?Pushover URL required}"

echo "[DEBUG] Radarr Payload: ${PAYLOAD}"

function _jq() {
    jq -r "${1:?}" <<<"${PAYLOAD}"
}

function notify() {
    local event_type=$(_jq '.eventType')

    case "${event_type}" in
        "Download")
            printf -v PUSHOVER_TITLE "Movie %s" \
                "$( [[ "$(_jq '.isUpgrade')" == "true" ]] && echo "Upgraded" || echo "Added" )"
            printf -v PUSHOVER_MESSAGE "<b>%s (%s)</b><small>\n%s</small><small>\n\n<b>Client:</b> %s</small>" \
                "$(_jq '.movie.title')" \
                "$(_jq '.movie.year')" \
                "$(_jq '.movie.overview')" \
                "$(_jq '.downloadClient')"
            printf -v PUSHOVER_URL "%s/movie/%s" \
                "$(_jq '.applicationUrl')" \
                "$(_jq '.movie.tmdbId')"
            printf -v PUSHOVER_URL_TITLE "View Movie"
            printf -v PUSHOVER_PRIORITY "low"
            ;;
        "ManualInteractionRequired")
            printf -v PUSHOVER_TITLE "Movie Requires Manual Interaction"
            printf -v PUSHOVER_MESSAGE "<b>%s (%s)</b><small>\n<b>Client:</b> %s</small>" \
                "$(_jq '.movie.title')" \
                "$(_jq '.movie.year')" \
                "$(_jq '.downloadClient')"
            printf -v PUSHOVER_URL "%s/activity/queue" "$(_jq '.applicationUrl')"
            printf -v PUSHOVER_URL_TITLE "View Queue"
            printf -v PUSHOVER_PRIORITY "high"
            ;;
        "Test")
            printf -v PUSHOVER_TITLE "Test Notification"
            printf -v PUSHOVER_MESSAGE "Howdy this is a test notification"
            printf -v PUSHOVER_URL "%s" "$(_jq '.applicationUrl')"
            printf -v PUSHOVER_URL_TITLE "View Movies"
            printf -v PUSHOVER_PRIORITY "low"
            ;;
        *)
            echo "[ERROR] Unknown event type: ${event_type}" >&2
            return 1
            ;;
    esac

    apprise -vv --title "${PUSHOVER_TITLE}" --body "${PUSHOVER_MESSAGE}" --input-format html \
        "${APPRISE_RADARR_PUSHOVER_URL}?url=${PUSHOVER_URL}&url_title=${PUSHOVER_URL_TITLE}&priority=${PUSHOVER_PRIORITY}&format=html"
}

function main() {
    notify
}

main "$@"
