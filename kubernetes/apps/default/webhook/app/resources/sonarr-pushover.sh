#!/usr/bin/env bash
set -Eeuo pipefail

PUSHOVER_URL=${1:?}
PAYLOAD=${2:?}

echo "[DEBUG] Payload: ${PAYLOAD}"

function _jq() {
    jq --raw-output "${1:?}" <<< "${PAYLOAD}"
}

function notify() {
    local event="$(_jq '.eventType')"
    local instance="$(_jq '.instanceName')"
    local url="$(_jq '.applicationUrl')"

    if [[ "${event}" == "Test" ]]; then
        printf -v pushover_title "Test Notification"
        printf -v pushover_msg "Howdy this is a test notification from <b>%s</b>" "${instance}"
        printf -v pushover_url "%s" "${url}"
        printf -v pushover_url_title "Open %s" "${instance}"
        printf -v pushover_priority "%s" "low"
    fi

    if [[ "${event}" == "ManualInteractionRequired" ]]; then
        printf -v pushover_title "%s Import Requires Manual Interaction" "Episode"
        printf -v pushover_msg "<b>%s (%s)</b><small>\n<b>Client:</b> %s</small>" \
            "$(_jq '.series.title')" \
            "$(_jq '.series.year')" \
            "$(_jq '.downloadClient')"
        printf -v pushover_url "%s/activity/queue" "${url}"
        printf -v pushover_url_title "View queue in %s" "${instance}"
        printf -v pushover_priority "%s" "high"
    fi

    if [[ "${event}" == "Download" ]]; then
        printf -v pushover_title "Episode %s" "$( [[ "$(_jq '.isUpgrade')" == "true" ]] && echo "Upgraded" || echo "Imported" )"
        printf -v pushover_msg "<b>%s (%s) S%02dE%02d</b><small>\n%s</small><small>\n\n<b>Quality:</b> %s</small><small>\n<b>Size:</b> %s</small><small>\n<b>Client:</b> %s</small><small>\n<b>Indexer:</b> %s</small>" \
            "$(_jq '.series.title')" \
            "$(_jq '.series.year')" \
            "$(_jq '.episodes[0].seasonNumber')" \
            "$(_jq '.episodes[0].episodeNumber')" \
            "$(_jq '.episodes[0].title')" \
            "$(_jq '.episodeFile.quality')" \
            "$(numfmt --to iec --format "%8.2f" "$(_jq '.episodeFile.size')")" \
            "$(_jq '.downloadClient')" \
            "$(_jq '.release.indexer')"
        printf -v pushover_url "%s/series/%s" \
            "${url}" \
            "$(_jq '.series.titleSlug')"
        printf -v pushover_url_title "View series in %s" "${instance}"
        printf -v pushover_priority "%s" "low"
    fi

    apprise -vv --title "${pushover_title}" --body "${pushover_msg}" \
        "${PUSHOVER_URL}?url=${pushover_url}&url_title=${pushover_url_title}&priority=${pushover_priority}&format=markdown"
}

function main() {
    notify
}

main "$@"
