#!/usr/bin/env bash

DEBUG="true"

ERRORS=()
PID_FILE="/config/*.pid" && [[ "${DEBUG}" == "true" ]] && PID_FILE="*.pid"
CONFIG_FILE="/config/config.xml" && [[ "${DEBUG}" == "true" ]] && CONFIG_FILE="config.xml"

#
# Discoverable variables
#
# shellcheck disable=SC2086
PUSHOVER_STARR_APP="$(basename --suffix=.pid -- ${PID_FILE})" && [[ -z "${PUSHOVER_STARR_APP}" ]] && ERRORS+=("PUSHOVER_STARR_APP not defined")
PUSHOVER_STARR_PORT="$(xmlstarlet sel -t -v "//Port" -nl ${CONFIG_FILE})" && [[ -z "${PUSHOVER_STARR_PORT}" ]] && ERRORS+=("PUSHOVER_STARR_PORT not defined")
PUSHOVER_STARR_APIKEY="$(xmlstarlet sel -t -v "//ApiKey" -nl ${CONFIG_FILE})" && [[ -z "${PUSHOVER_STARR_APIKEY}" ]] && ERRORS+=("PUSHOVER_STARR_APIKEY not defined")
PUSHOVER_STARR_EVENT_TYPE="${PUSHOVER_STARR_APP}_eventtype" && [[ -z "${!PUSHOVER_STARR_EVENT_TYPE}" ]] && ERRORS+=("PUSHOVER_STARR_EVENT_TYPE not defined")
# PUSHOVER_STARR_INSTANCE_NAME="$(xmlstarlet sel -t -v "//InstanceName" -nl ${CONFIG_FILE})" && [[ -z "${PUSHOVER_STARR_INSTANCE_NAME}" ]] && ERRORS+=("PUSHOVER_STARR_INSTANCE_NAME not defined")

#
# Configurable variables
#
# Required
PUSHOVER_STARR_INSTANCE_NAME="${PUSHOVER_STARR_INSTANCE_NAME:-}" && [[ -z "${PUSHOVER_STARR_INSTANCE_NAME}" ]] && ERRORS+=("PUSHOVER_STARR_INSTANCE_NAME not defined")
PUSHOVER_STARR_APP_URL="${PUSHOVER_STARR_APP_URL:-}" && [[ -z "${PUSHOVER_STARR_APP_URL}" ]] && ERRORS+=("PUSHOVER_STARR_APP_URL not defined")
PUSHOVER_USER_KEY="${PUSHOVER_USER_KEY:-}" && [[ -z "${PUSHOVER_USER_KEY}" ]] && ERRORS+=("PUSHOVER_USER_KEY not defined")
PUSHOVER_TOKEN="${PUSHOVER_TOKEN:-}" && [[ -z "${PUSHOVER_TOKEN}" ]] && ERRORS+=("PUSHOVER_TOKEN not defined")
# Optional
PUSHOVER_DEVICE="${PUSHOVER_DEVICE:-}"
PUSHOVER_PRIORITY="${PUSHOVER_PRIORITY:-"-1"}"
PUSHOVER_SOUND="${PUSHOVER_SOUND:-}"

#
# Print defined variables
#
for pushover_vars in ${!PUSHOVER_*}
do
    declare -n var="${pushover_vars}"
    [[ -n "${var}" ]] && printf "%s - %s=%s\n" "$(date)" "${!var}" "${var}"
done

#
# Validate required variables are set
#
if [ ${#ERRORS[@]} -gt 0 ]; then
    for err in "${ERRORS[@]}"; do printf "%s - Error %s\n" "$(date)" "${err}"; done
    exit 1
fi

#
# Send Notification on Test
#
if [[ "${!PUSHOVER_STARR_EVENT_TYPE}" == "Test" ]]; then
    PUSHOVER_TITLE="Test Notification"
    PUSHOVER_MESSAGE="Howdy fella this is a test notification from ${PUSHOVER_STARR_INSTANCE_NAME}"
fi

#
# Send notification on Download or Upgrade
#
if [[ "${!PUSHOVER_STARR_EVENT_TYPE}" == "Download" ]]; then
    case "${APPLICATION}" in
        sonarr)
            printf -v PUSHOVER_TITLE "%s - S%02dE%02d - %s [%s]" \
                "${sonarr_series_title:-}" \
                "${sonarr_episodefile_seasonnumber:-}" \
                "${sonarr_episodefile_episodenumbers:-}" \
                "${sonarr_episodefile_episodetitles:-}" \
                "${sonarr_episodefile_quality:-}"
            printf -v PUSHOVER_MESSAGE "%s" \
                "$(curl -s "http://localhost:${PUSHOVER_STARR_PORT}/api/v3/episode?seriesId=${sonarr_series_id:-}" \
                    --header "X-Api-Key:${PUSHOVER_STARR_APIKEY}" \
                        | jq -r ".[] | select(.id==${sonarr_episodefile_id:-}) | .overview")"
            ;;
        radarr)
            printf -v PUSHOVER_TITLE "%s (%s) [%s]" \
                "${radarr_movie_title:-}" \
                "${radarr_movie_year:-}" \
                "${radarr_moviefile_quality:-}"
            printf -v PUSHOVER_MESSAGE "%s" \
                "$(curl -s "http://localhost:${PUSHOVER_STARR_PORT}/api/v3/movie/${radarr_movie_id:-}" \
                    --header "X-Api-Key:${PUSHOVER_STARR_APIKEY}" \
                        | jq ".overview")"
            ;;
        lidarr)
            printf "Lidarr not implemented yet"
            exit 1
            ;;
        readarr)
            printf "Readarr not implemented yet"
            exit 1
            ;;
        whisparr)
            printf "Whisparr not implemented yet"
            exit 1
            ;;
        prowlarr)
            printf "Prowlarr not implemented yet"
            exit 1
            ;;
        *)
            printf "Not implemented yet"
            exit 1
            ;;
    esac
fi

notification=$(jq -n \
    --arg token "${PUSHOVER_TOKEN}" \
    --arg user "${PUSHOVER_USER_KEY}" \
    --arg title "${PUSHOVER_TITLE}" \
    --arg message "${PUSHOVER_MESSAGE}" \
    --arg url "${PUSHOVER_PUSHOVER_STARR_APP_URL}" \
    --arg url_title "View in ${PUSHOVER_STARR_INSTANCE_NAME}" \
    --arg priority "${PUSHOVER_PRIORITY}" \
    --arg sound "${PUSHOVER_SOUND}" \
    --arg device "${PUSHOVER_DEVICE}" \
    '{token: $token, user: $user, title: $title, message: $message, url: $url, url_title: $url_title, priority: $priority, sound: $sound, device: $device}' \
)

status_code="$(curl --write-out "%{http_code}" --silent --output /dev/null --header "Content-Type: application/json" --data-binary "${notification}" --request POST "https://api.pushover.net/1/messages.json")"
if [[ "${status_code}" -ne 200 ]]; then
    printf "%s - Unable to send notification: %s" "$(date)" "$(echo "${notification}" | jq -c)"
    exit 1
else
    printf "%s - Sent notification: %s" "$(date)" "$(echo "${notification}" | jq -c)"
    exit 0
fi
