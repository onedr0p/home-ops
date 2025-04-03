#!/usr/bin/env bash
set -Eeuo pipefail

PUSHOVER_URL=${1:?}
PAYLOAD=${2:?}

echo "[DEBUG] Payload: ${PAYLOAD}"

function _jq() {
    jq --raw-output "${1:?}" <<< "${PAYLOAD}"
}

function notify() {
    local event="$(_jq '.extra.event')"

    if [[ "${event}" == "TEST" ]]; then
        printf -v pushover_title "Test Notification"
        printf -v pushover_msg "Howdy this is a test notification from <b>%s</b>" "cross-seed"
        printf -v pushover_priority "%s" "low"
    fi

    apprise -vv --title "${pushover_title}" --body "${pushover_msg}" \
        "${PUSHOVER_URL}?priority=${pushover_priority}&format=html"
}

function main() {
    notify
}

main "$@"
