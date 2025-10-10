#!/usr/bin/env bash
# shellcheck disable=SC2154
set -euo pipefail

sonarr_series_id=618

[[ "${sonarr_eventtype}" == "Download" ]] || exit 0

curl_cmd=("curl" "-fsSL" "--header" "X-Api-Key: ${SONARR__AUTH__APIKEY}")
sonarr_api_url="http://localhost:${SONARR__SERVER__PORT}/api/v3"

# Get codec tags for a series
get_codec_tags() {
    "${curl_cmd[@]}" "${sonarr_api_url}/episodefile?seriesId=$1" | jq -r '
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
    local existing_tags tag_id

    existing_tags=$("${curl_cmd[@]}" "${sonarr_api_url}/tag")
    tag_id=$(echo "$existing_tags" | jq -r ".[] | select(.label == \"$tag_label\") | .id")

    if [[ -z "$tag_id" ]]; then
        tag_id=$("${curl_cmd[@]}" -X POST -H "Content-Type: application/json" \
            -d "{\"label\": \"$tag_label\"}" "${sonarr_api_url}/tag" | jq -r '.id')
    fi

    echo "$tag_id"
}

# Update series with codec tags
update_series_tags() {
    local series_data="$1"
    local codecs="$2"

    # Get current codec tag IDs (tags that start with "codec:")
    local current_codec_tags existing_tags
    existing_tags=$("${curl_cmd[@]}" "${sonarr_api_url}/tag")
    current_codec_tags=$(echo "$existing_tags" | jq -r '
        [.[] | select(.label | startswith("codec:")) | .id]'
    )

    # Remove existing codec tags
    series_data=$(echo "$series_data" | jq --argjson remove_tags "$current_codec_tags" '
        .tags |= map(select(. as $tag | $remove_tags | index($tag) | not))
    ')

    # Add new codec tags
    local new_tag_ids=()
    for codec in $codecs; do
        new_tag_ids+=($(get_or_create_tag "$codec"))
    done

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

series_data=$("${curl_cmd[@]}" "${sonarr_api_url}/series/${sonarr_series_id}")
series_title=$(echo "$series_data" | jq -r '.title')

# Skip if no episode files
[[ $(echo "$series_data" | jq -r '.statistics.episodeFileCount // 0') -eq 0 ]] && { echo "Skipping $series_title - no episode files"; exit 0; }

codecs=$(get_codec_tags "$sonarr_series_id")

# Skip if no codecs found
[[ -z "$codecs" ]] && { echo "Skipping $series_title - no codecs found"; exit 0; }

updated_data=$(update_series_tags "$series_data" "$codecs")

# Skip if no tag changes
[[ $(echo "$series_data" | jq -c '.tags') == $(echo "$updated_data" | jq -c '.tags') ]] && { echo "Skipping $series_title - no tag changes needed"; exit 0; }

echo "Updating $series_title with codecs: ${codecs//$'\n'/, }"
"${curl_cmd[@]}" -X PUT -H "Content-Type: application/json" -d "$updated_data" \
    "${sonarr_api_url}/series" &>/dev/null
