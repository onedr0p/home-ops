#!/usr/bin/env bash
set -Eeuo pipefail

PUSHOVER_URL=${1:?}
PAYLOAD=${2:?}

echo "[DEBUG] Payload: ${PAYLOAD}"

function _jq() {
    jq --raw-output "${1:?}" <<< "${PAYLOAD}"
}

function notify() {
    local type="$(_jq '.notification_type')"

    if [[ "${type}" == "TEST_NOTIFICATION" ]]; then
        printf -v pushover_title "Test Notification"
        printf -v pushover_msg "Howdy this is a test notification from <b>%s</b>" "Jellyseerr"
        printf -v pushover_url "%s" "https://requests.devbu.io"
        printf -v pushover_url_title "Open %s" "Jellyseerr"
        printf -v pushover_priority "%s" "low"
    fi

    apprise -vv --title "${pushover_title}" --body "${pushover_msg}" \
        "${PUSHOVER_URL}?url=${pushover_url}&url_title=${pushover_url_title}&priority=${pushover_priority}&format=markdown"
}

function main() {
    notify
}

main "$@"
