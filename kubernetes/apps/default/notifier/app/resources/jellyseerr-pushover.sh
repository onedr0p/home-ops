#!/usr/bin/env bash
set -euo pipefail

# Incoming arguments
PAYLOAD=${1:-}

# Required environment variables
: "${APPRISE_JELLYSEERR_PUSHOVER_URL:?Pushover URL required}"

echo "[DEBUG] Jellyseerr Payload: ${PAYLOAD}"

function _jq() {
    jq -r "${1:?}" <<<"${PAYLOAD}"
}

function notify() {
    local event_type=$(_jq '.notification_type')

    case "${event_type}" in
        "TEST_NOTIFICATION")
            printf -v PUSHOVER_TITLE "Test Notification"
            printf -v PUSHOVER_MESSAGE "Howdy this is a test notification from <b>%s</b>" "Jellyseerr"
            printf -v PUSHOVER_URL "%s" "https://requests.turbo.ac"
            printf -v PUSHOVER_URL_TITLE "Open %s" "Jellyseerr"
            printf -v PUSHOVER_PRIORITY "%s" "low"
            ;;
        "*")
            echo "[ERROR] Unknown event type: ${event_type}" >&2
            return 1
            ;;
    esac

    apprise -vv --title "${PUSHOVER_TITLE}" --body "${PUSHOVER_MESSAGE}" --input-format html \
        "${APPRISE_JELLYSEERR_PUSHOVER_URL}?url=${PUSHOVER_URL}&url_title=${PUSHOVER_URL_TITLE}&priority=${PUSHOVER_PRIORITY}&format=html"
}

function main() {
    notify
}

main "$@"
