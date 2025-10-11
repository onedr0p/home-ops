#!/usr/bin/env bash
set -euo pipefail

# Incoming environment variables
EVENT_TYPE="${sonarr_eventtype:-}"
SERIES_ID="${sonarr_series_id:-}"

# Only proceed for "Download" events with valid series ID
[[ "${EVENT_TYPE}" == "Download" && -n "${SERIES_ID}" ]] || exit 0

# Required environment variables
: "${SONARR__AUTH__APIKEY:?API key required}"
: "${SONARR__SERVER__PORT:?Server port required}"

# Setup curl command and base API URL
readonly CURL_CMD=("curl" "-fsSL" "--max-time" "30" "--header" "X-Api-Key: ${SONARR__AUTH__APIKEY}")
readonly SONARR_API_URL="http://localhost:${SONARR__SERVER__PORT}/api/v3"

# Get codec tags for a series
get_codec_tags() {
    "${CURL_CMD[@]}" "${SONARR_API_URL}/episodefile?seriesId=$1" | jq -r '
        [.[] | .mediaInfo.videoCodec // "other" |
         ascii_downcase | gsub("x"; "h") |
         if test("hevc") then "h265"
         elif test("divx|mpeg2|xvid") then "h264"
         elif test("av1") then "av1"
         elif test("h264|h265") then .
         else "other" end |
         "codec:" + .
        ] | unique | .[]'
}

# Get or create tag
get_or_create_tag() {
    local tag_label="$1"
    local tag_id

    tag_id=$("${CURL_CMD[@]}" "${SONARR_API_URL}/tag" | \
        jq -r --arg label "$tag_label" '.[] | select(.label == $label) | .id')

    if [[ -z "$tag_id" ]]; then
        tag_id=$("${CURL_CMD[@]}" -X POST -H "Content-Type: application/json" \
            --data-binary "$(jq -n --arg label "$tag_label" '{label: $label}')" \
            "${SONARR_API_URL}/tag" | jq -r '.id')
    fi

    echo "$tag_id"
}

# Update series with codec tags
update_series_tags() {
    local series_data="$1"
    local codecs="$2"

    # Get current codec tag IDs and remove them
    local current_codec_tags
    current_codec_tags=$("${CURL_CMD[@]}" "${SONARR_API_URL}/tag" | \
        jq -r '[.[] | select(.label | startswith("codec:")) | .id]')

    series_data=$(echo "$series_data" | jq --argjson remove_tags "$current_codec_tags" '
        .tags |= map(select(. as $tag | $remove_tags | index($tag) | not))
    ')

    # Add new codec tags
    local new_tag_ids=()
    while IFS= read -r codec; do
        [[ -n "$codec" ]] && new_tag_ids+=($(get_or_create_tag "$codec"))
    done <<< "$codecs"

    # Add new tags if any
    if [[ ${#new_tag_ids[@]} -gt 0 ]]; then
        local new_tags_json
        new_tags_json=$(printf '%s\n' "${new_tag_ids[@]}" | jq -R . | jq -s 'map(tonumber)')
        series_data=$(echo "$series_data" | jq --argjson add_tags "$new_tags_json" '
            .tags = (.tags + $add_tags | unique)
        ')
    fi

    echo "$series_data"
}

series_data=$("${CURL_CMD[@]}" "${SONARR_API_URL}/series/${SERIES_ID}")
series_title=$(echo "$series_data" | jq -r '.title')

# Skip if no episode files
if [[ $(echo "$series_data" | jq -r '.statistics.episodeFileCount // 0') -eq 0 ]]; then
    echo "Skipping $series_title - no episode files"
    exit 0
fi

codecs=$(get_codec_tags "${SERIES_ID}")

# Skip if no codecs found
if [[ -z "$codecs" ]]; then
    echo "Skipping $series_title - no codecs found"
    exit 0
fi

updated_data=$(update_series_tags "$series_data" "$codecs")

# Skip if no tag changes
if [[ $(echo "$series_data" | jq -c '.tags') == $(echo "$updated_data" | jq -c '.tags') ]]; then
    echo "Skipping $series_title - no tag changes needed"
    exit 0
fi

echo "Updating $series_title with codecs: ${codecs//$'\n'/, }"
"${CURL_CMD[@]}" -X PUT -H "Content-Type: application/json" \
    --data-binary "$updated_data" "${SONARR_API_URL}/series" >/dev/null
