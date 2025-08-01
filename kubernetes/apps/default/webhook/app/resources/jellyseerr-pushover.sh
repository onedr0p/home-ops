#!/usr/bin/env bash
set -Eeuo pipefail

JELLYSEERR_PUSHOVER_URL=${1:?}
PAYLOAD=${2:?}

echo "[DEBUG] Payload: ${PAYLOAD}"

function _jq() {
    jq --raw-output "${1:?}" <<<"${PAYLOAD}"
}

function notify() {
    local type="$(_jq '.notification_type')"

    if [[ "${type}" == "TEST_NOTIFICATION" ]]; then
        printf -v PUSHOVER_TITLE "Test Notification"
        printf -v PUSHOVER_MESSAGE "Howdy this is a test notification from <b>%s</b>" "Jellyseerr"
        printf -v PUSHOVER_URL "%s" "https://requests.turbo.ac"
        printf -v PUSHOVER_URL_TITLE "Open %s" "Jellyseerr"
        printf -v PUSHOVER_PRIORITY "%s" "low"
    fi

    apprise -vv --title "${PUSHOVER_TITLE}" --body "${PUSHOVER_MESSAGE}" --input-format html \
        "${JELLYSEERR_PUSHOVER_URL}?url=${PUSHOVER_URL}&url_title=${PUSHOVER_URL_TITLE}&priority=${PUSHOVER_PRIORITY}&format=html"
}

function main() {
    notify
}

main "$@"
