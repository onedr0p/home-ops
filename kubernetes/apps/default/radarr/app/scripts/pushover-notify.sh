#!/usr/bin/env bash

PUSHOVER_DEBUG="${PUSHOVER_DEBUG:-"true"}"
# kubectl port-forward service/radarr -n default 7878:7878
# export PUSHOVER_STARR_INSTANCE_NAME=Radarr;
# export PUSHOVER_APP_URL="";
# export PUSHOVER_TOKEN="";
# export PUSHOVER_USER_KEY="";
# export radarr_eventtype=Download;
# ./notify.sh

CONFIG_FILE="/config/config.xml" && [[ "${PUSHOVER_DEBUG}" == "true" ]] && CONFIG_FILE="config.xml"
ERRORS=()

#
# Discoverable variables
#
# shellcheck disable=SC2086
PUSHOVER_STARR_PORT="$(xmlstarlet sel -t -v "//Port" -nl ${CONFIG_FILE})" && [[ -z "${PUSHOVER_STARR_PORT}" ]] && ERRORS+=("PUSHOVER_STARR_PORT not defined")
PUSHOVER_STARR_APIKEY="$(xmlstarlet sel -t -v "//ApiKey" -nl ${CONFIG_FILE})" && [[ -z "${PUSHOVER_STARR_APIKEY}" ]] && ERRORS+=("PUSHOVER_STARR_APIKEY not defined")
PUSHOVER_STARR_INSTANCE_NAME="$(xmlstarlet sel -t -v "//InstanceName" -nl ${CONFIG_FILE})" && [[ -z "${PUSHOVER_STARR_INSTANCE_NAME}" ]] && ERRORS+=("PUSHOVER_STARR_INSTANCE_NAME not defined")

#
# Configurable variables
#
# Required
PUSHOVER_APP_URL="${PUSHOVER_APP_URL:-}" && [[ -z "${PUSHOVER_APP_URL}" ]] && ERRORS+=("PUSHOVER_APP_URL not defined")
PUSHOVER_USER_KEY="${PUSHOVER_USER_KEY:-}" && [[ -z "${PUSHOVER_USER_KEY}" ]] && ERRORS+=("PUSHOVER_USER_KEY not defined")
PUSHOVER_TOKEN="${PUSHOVER_TOKEN:-}" && [[ -z "${PUSHOVER_TOKEN}" ]] && ERRORS+=("PUSHOVER_TOKEN not defined")
# Optional
PUSHOVER_DEVICE="${PUSHOVER_DEVICE:-}"
PUSHOVER_PRIORITY="${PUSHOVER_PRIORITY:-"-2"}"
PUSHOVER_SOUND="${PUSHOVER_SOUND:-}"

#
# Print defined variables
#
for pushover_vars in ${!PUSHOVER_*}
do
    declare -n var="${pushover_vars}"
    [[ -n "${var}" && "${PUSHOVER_DEBUG}" = "true" ]] && printf "%s - %s=%s\n" "$(date)" "${!var}" "${var}"
done

#
# Validate required variables are set
#
if [ ${#ERRORS[@]} -gt 0 ]; then
    for err in "${ERRORS[@]}"; do printf "%s - Undefined variable %s\n" "$(date)" "${err}" >&2; done
    exit 1
fi

#
# Send Notification on Test
#
if [[ "${radarr_eventtype:-}" == "Test" ]]; then
    PUSHOVER_TITLE="Test Notification"
    PUSHOVER_MESSAGE="Howdy this is a test notification from ${PUSHOVER_STARR_INSTANCE_NAME}"
fi

#
# Send notification on Download or Upgrade
#
if [[ "${radarr_eventtype:-}" == "Download" ]]; then
    printf -v PUSHOVER_TITLE "%s (%s) [%s]" \
        "${radarr_movie_title:-"The Lord of the Rings: The Return of the King"}" \
        "${radarr_movie_year:-"2003"}" \
        "${radarr_moviefile_quality:-"Bluray-1080p"}"
    printf -v PUSHOVER_MESSAGE "%s" \
        "$(curl --silent --header "X-Api-Key:${PUSHOVER_STARR_APIKEY}" "http://localhost:${PUSHOVER_STARR_PORT}/api/v3/movie/${radarr_movie_id:-"2619"}" \
            | jq -r ".overview")"
    printf -v PUSHOVER_URL "https://%s/movie/%s" \
        "${PUSHOVER_APP_URL}" \
        "${radarr_movie_tmdbid:-"122"}"
    printf -v PUSHOVER_URL_TITLE "View movie in %s" \
        "${PUSHOVER_STARR_INSTANCE_NAME}"
fi

notification=$(jq -n \
    --arg token "${PUSHOVER_TOKEN}" \
    --arg user "${PUSHOVER_USER_KEY}" \
    --arg title "${PUSHOVER_TITLE}" \
    --arg message "${PUSHOVER_MESSAGE:-"Unable to obtain plot summary"}" \
    --arg url "${PUSHOVER_URL}" \
    --arg url_title "${PUSHOVER_URL_TITLE}" \
    --arg priority "${PUSHOVER_PRIORITY}" \
    --arg sound "${PUSHOVER_SOUND}" \
    --arg device "${PUSHOVER_DEVICE}" \
    '{token: $token, user: $user, title: $title, message: $message, url: $url, url_title: $url_title, priority: $priority, sound: $sound, device: $device}' \
)

status_code=$(curl \
    --write-out "%{http_code}" \
    --silent \
    --output /dev/null \
    --header "Content-Type: application/json" \
    --data-binary "${notification}" \
    --request POST "https://api.pushover.net/1/messages.json" \
)

if [[ "${status_code}" -ne 200 ]] ; then
    printf "%s - Unable to send notification with status code %s and payload: %s\n" "$(date)" "${status_code}" "$(echo "${notification}" | jq -c)" >&2
    exit 1
else
    printf "%s - Sent notification with status code %s and payload: %s\n" "$(date)" "${status_code}" "$(echo "${notification}" | jq -c)"
fi
