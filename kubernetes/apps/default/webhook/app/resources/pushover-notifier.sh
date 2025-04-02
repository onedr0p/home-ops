#!/usr/bin/env bash
set -Eeuo pipefail

APP=${1:?}
PUSHOVER_URI=${2:?}
PAYLOAD=${3:?}

echo "Pushover Notifier for ${APP}"
echo "Pushover URI: ${PUSHOVER_URI}"
echo "Payload: ${PAYLOAD}"

if [[ "${APP}" == "radarr" || "${APP}" == "sonarr" ]]; then

    EVENT_TYPE=$(echo "${PAYLOAD}" | jsonpath -i '$.eventtype' -b)
    INSTANCE=$(echo "${PAYLOAD}" | jsonpath -i '$.instancename' -b)
    APPLICATION_URL=$(echo "${PAYLOAD}" | jsonpath -i '$.applicationurl' -b)

    if [[ "${EVENT_TYPE}" == "Test" ]]; then
        apprise -vv \
            -t "Test Notification" \
            -b "Howdy this is a test notification from ${INSTANCE:-${APP}}" \
            "${PUSHOVER_URI}?url=${APPLICATION_URL}&url_title=Open ${INSTANCE:-${APP}}&priority=-2"
    fi

    if [[ "${EVENT_TYPE}" == "Download" ]]; then
        echo "${PAYLOAD}"
    fi

    if [[ "${EVENT_TYPE}" == "ManualInteractionRequired" ]]; then
        echo "${PAYLOAD}"
    fi

fi
