#!/usr/bin/env bash
# shellcheck disable=SC2154

PUSHOVER_DEBUG="${PUSHOVER_DEBUG:-"false"}"
# kubectl port-forward service/sonarr -n default 8989:80
# export PUSHOVER_TOKEN="";
# export PUSHOVER_USER_KEY="";
# export sonarr_eventtype=Download;
# ./pushover-notify.sh

CONFIG_FILE="/config/config.xml" && [[ "${PUSHOVER_DEBUG}" == "true" ]] && CONFIG_FILE="config.xml"
ERRORS=()

#
# Configurable variables
#
# Required
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
if [[ "${sonarr_eventtype:-}" == "Test" ]]; then
    PUSHOVER_TITLE="Test Notification"
    PUSHOVER_MESSAGE="Howdy this is a test notification from ${sonarr_instancename:-Sonarr}"
fi

#
# Send notification on Download or Upgrade
#
if [[ "${sonarr_eventtype:-}" == "Download" ]]; then
    if [[ "${sonarr_isupgrade}" == "True" ]]; then pushover_title="Upgraded"; else pushover_title="Downloaded"; fi
    printf -v PUSHOVER_TITLE "Episode %s" "${pushover_title}"
    printf -v PUSHOVER_MESSAGE "<b>%s (S%02dE%02d)</b><small>\n%s</small><small>\n\n<b>Client:</b> %s</small><small>\n<b>Quality:</b> %s</small>" \
        "${sonarr_series_title}" \
        "${sonarr_episodefile_seasonnumber}" \
        "${sonarr_episodefile_episodenumbers}" \
        "${sonarr_episodefile_episodetitles}" \
        "${sonarr_download_client}" \
        "${sonarr_episodefile_quality}"
    printf -v PUSHOVER_URL "%s/series/%s" "${sonarr_applicationurl:-localhost}" "${sonarr_series_titleslug}"
    printf -v PUSHOVER_URL_TITLE "View series in %s" "${sonarr_instancename:-Sonarr}"
fi

#
# Send notification on Manual Interaction Required
#
if [[ "${sonarr_eventtype:-}" == "ManualInteractionRequired" ]]; then
    PUSHOVER_PRIORITY="1"
    printf -v PUSHOVER_TITLE "Episode requires manual interaction"
    printf -v PUSHOVER_MESSAGE "<b>%s</b><small>\n<b>Client:</b> %s</small>" \
        "${sonarr_series_title}" \
        "${sonarr_download_client}"
    printf -v PUSHOVER_URL "%s/activity/queue" "${sonarr_applicationurl:-localhost}"
    printf -v PUSHOVER_URL_TITLE "View queue in %s" "${sonarr_instancename:-Sonarr}"
fi

notification=$(jq -n \
    --arg token "${PUSHOVER_TOKEN}" \
    --arg user "${PUSHOVER_USER_KEY}" \
    --arg title "${PUSHOVER_TITLE}" \
    --arg message "${PUSHOVER_MESSAGE}" \
    --arg url "${PUSHOVER_URL}" \
    --arg url_title "${PUSHOVER_URL_TITLE}" \
    --arg priority "${PUSHOVER_PRIORITY}" \
    --arg sound "${PUSHOVER_SOUND}" \
    --arg device "${PUSHOVER_DEVICE}" \
    --arg html "1" \
    '{token: $token, user: $user, title: $title, message: $message, url: $url, url_title: $url_title, priority: $priority, sound: $sound, device: $device, html: $html}' \
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
