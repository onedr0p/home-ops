#!/usr/bin/env bash
set -Eeuo pipefail

# Remove the port from the IP address since Sonarr listens on port 80
SONARR_REMOTE_ADDR=${SONARR_REMOTE_ADDR%%:*}

# Cache existing tags once at the start
declare -A TAG_CACHE

# Function to cache existing tags
function cache_existing_tags() {
    existing_tags_cache=$(curl -fsSL --header "X-Api-Key: ${SONARR_API_KEY}" "http://${SONARR_REMOTE_ADDR}/api/v3/tag")
    while IFS=":" read -r id label; do
        TAG_CACHE["$id"]="$label"
    done < <(echo "${existing_tags_cache}" | jq --raw-output '.[] | "\(.id):\(.label)"')
}

# Function to get codec tags for a series
function get_codec_tags() {
    local series_id=$1

    # Extract and map codecs in one pass
    local codecs
    codecs=$(
        curl -fsSL --header "X-Api-Key: ${SONARR_API_KEY}" "http://${SONARR_REMOTE_ADDR}/api/v3/episodefile?seriesId=${series_id}" | jq --raw-output '
        [
            .[] |
            (.mediaInfo.videoCodec // "other" |
            gsub("x"; "h") | ascii_downcase |
            if test("hevc") then "h265"
            elif test("divx|mpeg2|xvid") then "h264"
            elif test("av1") then "av1"
            elif test("h264|h265") then . else "other" end
            ) | "codec:" + .
        ] | unique | .[]'
    )

    echo "${codecs[@]}"
}

# Function to check if a tag exists, if not create it and return the tag ID
function get_or_create_tag_id() {
    local tag_label=$1
    local tag_id

    # Search cached tags
    tag_id=$(echo "${existing_tags_cache}" | jq --raw-output ".[] | select(.label == \"${tag_label}\") | .id")

    # If tag doesn't exist, create it
    if [[ -z "${tag_id}" ]]; then
        local new_tag
        new_tag=$(curl -fsSL --request POST --header "X-Api-Key: ${SONARR_API_KEY}" --header "Content-Type: application/json" --data "$(jo label="${tag_label}")" "http://${SONARR_REMOTE_ADDR}/api/v3/tag")
        tag_id=$(echo "${new_tag}" | jq --raw-output '.id')

        # Update cache
        existing_tags_cache=$(echo "${existing_tags_cache}" | jq ". += [{\"id\": ${tag_id}, \"label\": \"${tag_label}\"}]")
        TAG_CACHE["$tag_id"]="${tag_label}"
    fi

    echo "${tag_id}"
}

# Function to update series tags in bulk
function update_series_tags() {
    local series_data="$1"
    local codecs="$2"

    # Get the current series tags
    local series_tags
    series_tags=$(echo "$series_data" | jq --raw-output '.tags')

    # Track tags to add/remove
    local tags_to_add=()
    local tags_to_remove=()

    # Identify tags to add
    for codec in $codecs; do
        local tag_id
        tag_id=$(get_or_create_tag_id "${codec}")
        if ! echo "${series_tags}" | jq --exit-status ". | index(${tag_id})" &>/dev/null; then
            tags_to_add+=("$tag_id")
        fi
    done

    # Identify tags to remove
    for tag_id in $(echo "${series_tags}" | jq --raw-output '.[]'); do
        local tag_label="${TAG_CACHE[$tag_id]}"
        if [[ -n "${tag_label}" && ! " ${codecs} " =~ ${tag_label} ]] && [[ "${tag_label}" =~ codec:.* ]]; then
            tags_to_remove+=("$tag_id")
        fi
    done

    if [[ ${#tags_to_add[@]} -gt 0 ]]; then
        series_data=$(echo "${series_data}" | jq --argjson add_tags "$(printf '%s\n' "${tags_to_add[@]}" | jq --raw-input . | jq --slurp 'map(tonumber)')" '.tags = (.tags + $add_tags | unique)')
    fi

    if [[ ${#tags_to_remove[@]} -gt 0 ]]; then
        series_data=$(echo "${series_data}" | jq --argjson remove_tags "$(printf '%s\n' "${tags_to_remove[@]}" | jq --raw-input . | jq --slurp 'map(tonumber)')" '.tags |= map(select(. as $tag | $remove_tags | index($tag) | not))')
    fi

    echo "${series_data}"
}

function tag() {
    if [[ "${SONARR_EVENT_TYPE}" == "Test" ]]; then
        echo "[DEBUG] test event received from ${SONARR_REMOTE_ADDR}, nothing to do ..."
    elif [[ "${SONARR_EVENT_TYPE}" == "Download" ]]; then
        cache_existing_tags

        local orig_series_data
        orig_series_data=$(curl -fsSL --header "X-Api-Key: ${SONARR_API_KEY}" "http://${SONARR_REMOTE_ADDR}/api/v3/series/${SONARR_SERIES_ID}")

        local series_episode_file_count
        series_episode_file_count=$(echo "${orig_series_data}" | jq --raw-output '.statistics.episodeFileCount')

        if [[ "${series_episode_file_count}" == "null" || "${series_episode_file_count}" -eq 0 ]]; then
            echo "Skipping ${SONARR_SERIES_TITLE} (ID: ${SONARR_SERIES_ID}) due to no episode files"
            exit 0
        fi

        # Get unique codecs for the series
        local codecs
        codecs=$(get_codec_tags "${SONARR_SERIES_ID}")

        # Update the series tags
        local updated_series_data
        updated_series_data=$(update_series_tags "${orig_series_data}" "${codecs}")

        local orig_tags updated_tags
        orig_tags=$(echo "${orig_series_data}" | jq --compact-output '.tags')
        updated_tags=$(echo "${updated_series_data}" | jq --compact-output '.tags')

        if [[ "${orig_tags}" == "${updated_tags}" ]]; then
            echo "[INFO] skipping ${SONARR_SERIES_TITLE} (ID: ${SONARR_SERIES_ID}, Tags: [${codecs//$'\n'/,}]) due to no changes"
            exit 0
        fi

        echo "[INFO] updating ${SONARR_SERIES_TITLE} (ID: ${SONARR_SERIES_ID}, Tags: [${codecs//$'\n'/,}])"

        curl -fsSL --header "X-Api-Key: ${SONARR_API_KEY}" \
            --request PUT \
            --header "Content-Type: application/json" \
            --data "${updated_series_data}" "http://${SONARR_REMOTE_ADDR}/api/v3/series" &>/dev/null
    fi
}

function main() {
    tag
}

main "$@"
