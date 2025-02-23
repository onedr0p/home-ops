#!/usr/bin/env bash
set -Eeuo pipefail

CURL_CMD=("curl" "-fsSL" "--header" "X-Api-Key: ${SONARR__AUTH__APIKEY:-}")
SONARR_API_URL="http://localhost:${SONARR__SERVER__PORT:-}/api/v3"

# Cache existing tags once at the start
declare -A TAG_CACHE
cache_existing_tags() {
    existing_tags_cache=$("${CURL_CMD[@]}" "${SONARR_API_URL}/tag")
    while IFS=":" read -r id label; do
        TAG_CACHE["$id"]="$label"
    done < <(echo "${existing_tags_cache}" | jq --raw-output '.[] | "\(.id):\(.label)"')
}

# Function to get codec tags for a series
get_codec_tags() {
    local series_id=$1

    # Extract and map codecs in one pass
    codecs=$("${CURL_CMD[@]}" "${SONARR_API_URL}/episodefile?seriesId=${series_id}" | jq --raw-output '
        [
            .[] |
            (.mediaInfo.videoCodec // "other" |
            gsub("x"; "h") | ascii_downcase |
            if test("hevc") then "h265"
            elif test("divx|mpeg2|xvid") then "h264"
            elif test("av1") then "av1"
            elif test("h264|h265") then . else "other" end
            ) | "codec:" + .
        ] | unique | .[]
    ')

    echo "${codecs[@]}"
}

# Function to check if a tag exists, if not create it and return the tag ID
get_or_create_tag_id() {
    local tag_label=$1
    local tag_id

    # Search cached tags
    tag_id=$(echo "${existing_tags_cache}" | jq --raw-output ".[] | select(.label == \"${tag_label}\") | .id")

    # If tag doesn't exist, create it
    if [[ -z "${tag_id}" ]]; then
        new_tag=$("${CURL_CMD[@]}" -X POST -H "Content-Type: application/json" -d "{\"label\": \"${tag_label}\"}" "${SONARR_API_URL}/tag")
        tag_id=$(echo "${new_tag}" | jq --raw-output '.id')

        # Update cache
        existing_tags_cache=$(echo "${existing_tags_cache}" | jq ". += [{\"id\": ${tag_id}, \"label\": \"${tag_label}\"}]")
        TAG_CACHE["$tag_id"]="${tag_label}"
    fi

    echo "${tag_id}"
}

# Function to update series tags in bulk
update_series_tags() {
    local series_data="$1"
    local codecs="$2"

    # Get the current series tags
    series_tags=$(echo "$series_data" | jq --raw-output '.tags')

    # Track tags to add/remove
    tags_to_add=()
    tags_to_remove=()

    # Identify tags to add
    for codec in $codecs; do
        tag_id=$(get_or_create_tag_id "${codec}")
        if ! echo "${series_tags}" | jq --exit-status ". | index(${tag_id})" &> /dev/null; then
            tags_to_add+=("$tag_id")
        fi
    done

    # Identify tags to remove
    for tag_id in $(echo "${series_tags}" | jq --raw-output '.[]'); do
        tag_label="${TAG_CACHE[$tag_id]}"
        if [[ -n "${tag_label}" && ! " ${codecs} " =~ ${tag_label} ]] && [[ "${tag_label}" =~ codec:.* ]]; then
            tags_to_remove+=("$tag_id")
        fi
    done

    if [[ ${#tags_to_add[@]} -gt 0 ]]; then
        series_data=$(echo "${series_data}" | jq --argjson add_tags "$(printf '%s\n' "${tags_to_add[@]}" | jq --raw-input . | jq --slurp 'map(tonumber)')" '
            .tags = (.tags + $add_tags | unique)
        ')
    fi

    if [[ ${#tags_to_remove[@]} -gt 0 ]]; then
        series_data=$(echo "${series_data}" | jq --argjson remove_tags "$(printf '%s\n' "${tags_to_remove[@]}" | jq --raw-input . | jq --slurp 'map(tonumber)')" '
            .tags |= map(select(. as $tag | $remove_tags | index($tag) | not))
        ')
    fi

    echo "${series_data}"
}


if [[ "${sonarr_eventtype:-}" == "Download" ]]; then
    cache_existing_tags

    orig_series_data=$("${CURL_CMD[@]}" "${SONARR_API_URL}/series/${sonarr_series_id:-}?includeSeasonImages=false")
    series_title=$(echo "${orig_series_data}" | jq --raw-output '.title')
    series_episode_file_count=$(echo "${orig_series_data}" | jq --raw-output '.statistics.episodeFileCount')

    if [[ "${series_episode_file_count}" == "null" || "${series_episode_file_count}" -eq 0 ]]; then
        echo "Skipping ${series_title} (ID: ${sonarr_series_id:-}) due to no episode files"
        exit 0
    fi

    # Get unique codecs for the series
    codecs=$(get_codec_tags "${sonarr_series_id:-}")

    # Update the series tags
    updated_series_data=$(update_series_tags "${orig_series_data}" "${codecs}")

    orig_tags=$(echo "${orig_series_data}" | jq --compact-output '.tags')
    updated_tags=$(echo "${updated_series_data}" | jq --compact-output '.tags')

    if [[ "${orig_tags}" == "${updated_tags}" ]]; then
        echo "Skipping ${series_title} (ID: ${sonarr_series_id:-}, Tags: [${codecs//$'\n'/,}]) due to no changes"
        exit 0
    fi

    echo "Updating ${series_title} (ID: ${sonarr_series_id:-}, Tags: [${codecs//$'\n'/,}])"

    "${CURL_CMD[@]}" \
        --request PUT \
        --header "Content-Type: application/json" \
        --data "${updated_series_data}" "${SONARR_API_URL}/series" &> /dev/null
fi
