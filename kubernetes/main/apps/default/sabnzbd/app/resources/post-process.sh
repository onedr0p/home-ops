#!/usr/bin/env bash
# shellcheck disable=SC2154

# Incoming variables from sabnzbd
SAB_BYTES="${SAB_BYTES:-}"
SAB_CAT="${SAB_CAT:-}"
SAB_COMPLETE_DIR="${SAB_COMPLETE_DIR:-}"
SAB_FILENAME="${SAB_FILENAME:-}"
SAB_PP_STATUS="${SAB_PP_STATUS:-}"

# User defined variables for cross-seed and pushover
CROSS_SEED_HOST="${CROSS_SEED_HOST:-required}"
CROSS_SEED_PORT="${CROSS_SEED_PORT:-required}"
CROSS_SEED_API_KEY="${CROSS_SEED_API_KEY:-required}"
CROSS_SEED_SLEEP_INTERVAL="${CROSS_SEED_SLEEP_INTERVAL:-30}"
PUSHOVER_USER_KEY="${PUSHOVER_USER_KEY:-required}"
PUSHOVER_TOKEN="${PUSHOVER_TOKEN:-required}"

# Check if post-processing was successful
if [[ "${SAB_PP_STATUS}" -ne 0 ]]; then
    printf "post-processing failed with sabnzbd status code %s\n" "${SAB_PP_STATUS}" >&2
    exit 1
fi

# Update permissions on the search path
chmod -R 750 "${SAB_COMPLETE_DIR}"

# Send pushover notification
printf -v PUSHOVER_MESSAGE \
    "<b>%s</b><small>\n\n<b>Category:</b> %s</small><small>\n<b>Size:</b> %s</small>" \
    "${SAB_FILENAME}" "${SAB_CAT}" "$(numfmt --to iec --format "%8.2f" "${SAB_BYTES}")"

json_data=$(jo \
    token="${PUSHOVER_TOKEN}" \
    user="${PUSHOVER_USER_KEY}" \
    title="Sabnzbd Download Complete" \
    message="${PUSHOVER_MESSAGE}" \
    priority="-2" \
    html="1"
)

pushover_status_code=$(curl \
    --silent \
    --write-out "%{http_code}" \
    --output /dev/null \
    --request POST  \
    --header "Content-Type: application/json" \
    --data-binary "${json_data}" \
    "https://api.pushover.net/1/messages.json" \
)

if [[ "${pushover_status_code}" -ne 200 ]] ; then
    printf "pushover notification failed to send with HTTP status code %s and payload: %s\n" "${pushover_status_code}" "$(echo "${json_data}" | jq --compact-output)" >&2
else
    printf "pushover notification sent with HTTP status code %s and payload: %s\n" "${pushover_status_code}" "$(echo "${json_data}" | jq --compact-output)"
fi

# Search for cross-seed
cross_seed_status_code=$(curl \
    --silent \
    --output /dev/null \
    --write-out "%{http_code}" \
    --request POST \
    --data-urlencode "path=${SAB_COMPLETE_DIR}" \
    --header "X-Api-Key: ${CROSS_SEED_API_KEY}" \
    "http://${CROSS_SEED_HOST}:${CROSS_SEED_PORT}/api/webhook"
)

if [[ "${cross_seed_status_code}" -ne 204 ]]; then
    printf "cross-seed search failed with status code %s and path %s\n" "${cross_seed_status_code}" "${SAB_COMPLETE_DIR}"
else
    printf "cross-seed search success with status code %s and path %s\n" "${cross_seed_status_code}" "${SAB_COMPLETE_DIR}"
    sleep "${CROSS_SEED_SLEEP_INTERVAL}"
fi
