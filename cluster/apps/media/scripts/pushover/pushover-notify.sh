#!/usr/bin/env bash

PUSHOVER_API_URL="https://api.pushover.net/1/messages.json"

#
# Application specific variables
#
STARR_APP="$(basename --suffix=.pid -- /config/*.pid)"
STARR_PORT="$(xmlstarlet sel -t -v "//Port" -nl /config/config.xml)"
STARR_APIKEY="$(xmlstarlet sel -t -v "//ApiKey" -nl /config/config.xml)"
STARR_EVENT_TYPE="${STARR_APP}_eventtype"
# TODO: Not all starr apps support InstanceName yet, this will
# replace having a env var for STARR_INSTANCE_NAME in the future
# STARR_INSTANCE_NAME="$(xmlstarlet sel -t -v "//InstanceName" -nl config.xml)"

#
# Configurable environment variables
#
STARR_INSTANCE_NAME="${STARR_INSTANCE_NAME:-}"    # (required)
STARR_APP_URL="${STARR_APP_URL:-}"                # (required)
PUSHOVER_USER_KEY="${PUSHOVER_USER_KEY:-}"        # (required)
PUSHOVER_TOKEN="${PUSHOVER_TOKEN:-}"              # (required)
PUSHOVER_DEVICE="${PUSHOVER_DEVICE:-}"            # (optional)
PUSHOVER_PRIORITY="${PUSHOVER_PRIORITY:-}"        # (optional)
PUSHOVER_SOUND="${PUSHOVER_SOUND:-}"              # (optional)

for pushover_vars in ${!PUSHOVER_*}
do
    declare -n var="${pushover_vars}"
    printf "%s=%s\n" "${!var}" "${var}"
done

for starr_vars in ${!STARR_*}
do
    declare -n var="${starr_vars}"
    printf "%s=%s\n" "${!var}" "${var}"
done

#
# Send Notification on Test
#
if [[ "${!STARR_EVENT_TYPE}" == "Test" ]]; then
    PUSHOVER_TITLE="Test Notification"
    PUSHOVER_MESSAGE="Howdy fella this is a test notification from ${STARR_INSTANCE_NAME}"
fi

#
# Send notification on Download or Upgrade
#
if [[ "${!STARR_EVENT_TYPE}" == "Download" ]]; then
    case "${APPLICATION}" in
        sonarr)
            printf -v PUSHOVER_TITLE "%s - S%02dE%02d - %s [%s]" \
                "${sonarr_series_title:-}" \
                "${sonarr_episodefile_seasonnumber:-}" \
                "${sonarr_episodefile_episodenumbers:-}" \
                "${sonarr_episodefile_episodetitles:-}" \
                "${sonarr_episodefile_quality:-}"
            printf -v PUSHOVER_MESSAGE "%s" \
                "$(curl -s "http://localhost:${STARR_PORT}/api/v3/episode?seriesId=${sonarr_series_id:-}" \
                    --header "X-Api-Key:${STARR_APIKEY}" \
                        | jq -r ".[] | select(.id==${sonarr_episodefile_id:-}) | .overview")"
            ;;
        radarr)
            printf -v PUSHOVER_TITLE "%s (%s) [%s]" \
                "${radarr_movie_title:-}" \
                "${radarr_movie_year:-}" \
                "${radarr_moviefile_quality:-}"
            printf -v PUSHOVER_MESSAGE "%s" \
                "$(curl -s "http://localhost:${STARR_PORT}/api/v3/movie/${radarr_movie_id:-}" \
                    --header "X-Api-Key:${STARR_APIKEY}" \
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
        --arg url "${STARR_APP_URL}" \
        --arg url_title "View in ${STARR_INSTANCE_NAME}" \
        --arg priority "${PUSHOVER_PRIORITY}" \
        --arg sound "${PUSHOVER_SOUND}" \
        --arg device "${PUSHOVER_DEVICE}" \
        '{token: $token, user: $user, title: $title, message: $message, url: $url, url_title: $url_title, priority: $priority, sound: $sound, device: $device}' \
    )

status_code="$(curl --write-out "%{http_code}" --silent --output /dev/null --header "Content-Type: application/json" --data-binary "${notification}" --request POST "${PUSHOVER_API_URL}")"
if [[ "${status_code}" -ne 200 ]]; then
    printf "%s - Unable to send notification: %s" "$(date)" "$(echo "${notification}" | jq -c)"
    exit 1
else
    printf "%s - Sent notification: %s" "$(date)" "$(echo "${notification}" | jq -c)"
    exit 0
fi
