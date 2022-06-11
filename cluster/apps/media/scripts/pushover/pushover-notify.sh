#!/usr/bin/env bash

export PUSHOVARR_PUSHOVER_API_URL="https://api.pushover.net/1/messages.json"

#
# Application specific variables
#
PUSHOVARR_STARR_APP="$(basename --suffix=.pid -- /config/*.pid)"
PUSHOVARR_STARR_PORT="$(xmlstarlet sel -t -v "//Port" -nl /config/config.xml)"
PUSHOVARR_STARR_APIKEY="$(xmlstarlet sel -t -v "//ApiKey" -nl /config/config.xml)"
PUSHOVARR_STARR_EVENT_TYPE="${PUSHOVARR_STARR_APP}_eventtype"
# TODO: Not all starr apps support InstanceName yet, this will
# replace PUSHOVARR_APP_DISPLAY_NAME in the future
# export PUSHOVARR_STARR_INSTANCE_NAME
# PUSHOVARR_STARR_INSTANCE_NAME="$(xmlstarlet sel -t -m '/Config/InstanceName' -v Value </config/config.xml)"

#
# Configurable environment variables
#
PUSHOVARR_STARR_INSTANCE_NAME=""      # (required)
PUSHOVARR_STARR_APP_URL=""            # (required)
PUSHOVARR_PUSHOVER_USER_KEY=""        # (required)
PUSHOVARR_PUSHOVER_TOKEN=""           # (required)
PUSHOVARR_PUSHOVER_DEVICE=""          # (optional)
PUSHOVARR_PUSHOVER_PRIORITY=""        # (optional)
PUSHOVARR_PUSHOVER_SOUND=""           # (optional)

for variable in ${!PUSHOVARR_*}
do
    declare -n var=$variable
    printf "\"%s=%s\"," "${!var}" "${var}"
done

exit 0


#
# Send Notification on Test
#
if [[ "${!PUSHOVARR_STARR_EVENT_TYPE}" == "Test" ]]; then
    send "Test Notification" "Test Message"
    exit 0
fi

#
# Send notification on Download
#
if [[ "${!PUSHOVARR_STARR_EVENT_TYPE}" == "Download" ]]; then
    case "${APPLICATION}" in
        sonarr)
            #shellcheck disable=SC2154
            printf -v PUSHOVER_TITLE "%s - S%02dE%02d - %s" "${sonarr_series_title}" "${sonarr_episodefile_seasonnumber}" "${sonarr_episodefile_episodenumbers}" "${sonarr_episodefile_episodetitles}"
            #shellcheck disable=SC2154
            printf -v PUSHOVER_MESSAGE "%s" "${sonarr_episode_description}"
            ;;
        radarr)
            send
            ;;
        lidarr)
            send
            ;;
        readarr)
            send
            ;;
        *)
            printf "Unknown application"
            exit 1
            ;;
    esac
    send "${PUSHOVER_TITLE}" "${PUSHOVER_MESSAGE}"
    exit 0
fi

send() {
    local pushover_title="${1}"
    local pushover_message="${2}"
    local msg=
    msg=$(jq -n \
            --arg token "${PUSHOVARR_PUSHOVER_TOKEN}" \
            --arg user "${PUSHOVARR_PUSHOVER_USER_KEY}" \
            --arg title "${pushover_title}" \
            --arg message "${pushover_message}" \
            --arg url "${PUSHOVARR_STARR_APP_URL}" \
            --arg url_title "View in ${PUSHOVARR_STARR_INSTANCE_NAME}" \
            --arg priority "${PUSHOVARR_PUSHOVER_PRIORITY}" \
            --arg sound "${PUSHOVARR_PUSHOVER_SOUND}" \
            --arg device "${PUSHOVARR_PUSHOVER_DEVICE}" \
            '{token: $token, user: $user, title: $title, message: $message, url: $url, url_title: $url_title, priority: $priority, sound: $sound, device: $device}' \
        )

    curl \
        --header "Content-Type: application/json" \
        --data-binary "${msg}" \
        --request POST "${PUSHOVARR_PUSHOVER_API_URL}"
}
