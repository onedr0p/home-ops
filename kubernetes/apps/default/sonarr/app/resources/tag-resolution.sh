#!/usr/bin/env bash
set -euo pipefail

# Incoming environment variables
EVENT_TYPE="${sonarr_eventtype:-}"
SERIES_ID="${sonarr_series_id:-}"

# Only proceed for "Download" events or no event (manual bulk run)
[[ -z "${EVENT_TYPE}" || "${EVENT_TYPE}" == "Download" ]] || exit 0

# Required environment variables
: "${SONARR__AUTH__APIKEY:?API key required}"
: "${SONARR__SERVER__PORT:?Server port required}"

# Setup base API URL
readonly SONARR_API_URL="http://localhost:${SONARR__SERVER__PORT}/api/v3"

# Prefix for all tags managed by this script
readonly TAG_PREFIX="resolution:"

# Wrapper for API calls
api_call() {
    curl -fsSL --max-time 30 \
        --header "Content-Type: application/json" \
        --header "X-Api-Key: ${SONARR__AUTH__APIKEY}" \
        "$@"
}

# Fetch all existing tags
tags=$(api_call "${SONARR_API_URL}/tag")

# Refresh managed tag IDs from tags cache
refresh_managed_ids() {
    managed_tag_ids_json=$(jq -c --arg pfx "${TAG_PREFIX}" \
        '[.[] | select(.label | startswith($pfx)) | .id]' <<< "${tags}")
}
refresh_managed_ids

# Ensure a tag exists; sets REPLY to the tag ID (avoids subshell)
ensure_tag() {
    local label="$1"
    REPLY=$(jq -r --arg l "${label}" '.[] | select(.label == $l) | .id' <<< "${tags}")
    if [[ -z "${REPLY}" ]]; then
        REPLY=$(api_call -X POST --data-binary "{\"label\":\"${label}\"}" \
            "${SONARR_API_URL}/tag" | jq -r '.id')
        # Refresh tags cache in the current shell
        tags=$(api_call "${SONARR_API_URL}/tag")
        refresh_managed_ids
    fi
}

# Tag a single series; accepts series JSON as $2 (bulk) or fetches it (single)
tag_series() {
    local sid="$1"
    local series_json="${2:-}"

    # Get all episode files for the series and extract unique resolutions
    mapfile -t resolutions < <(
        api_call "${SONARR_API_URL}/episodefile?seriesId=${sid}" \
            | jq -r '[.[].quality.quality.resolution] | unique | .[] | select(. > 0) | "\(.)p"'
    )

    # Ensure tags exist and collect their IDs
    active_tag_ids=()
    for res in "${resolutions[@]+"${resolutions[@]}"}"; do
        ensure_tag "${TAG_PREFIX}${res}"
        active_tag_ids+=("${REPLY}")
    done

    local add_json
    if (( ${#active_tag_ids[@]} == 0 )); then
        add_json='[]'
    else
        add_json=$(printf '%s\n' "${active_tag_ids[@]}" | jq -R 'tonumber' | jq -s '.')
    fi

    # Use cached series JSON in bulk mode, otherwise fetch it
    if [[ -z "${series_json}" ]]; then
        series_json=$(api_call "${SONARR_API_URL}/series/${sid}")
    fi

    local title
    title=$(jq -r '.title' <<< "${series_json}")
    echo "Processing ${title} (${sid})..."

    # Remove all managed resolution: tags, then add active ones
    local updated current_tags new_tags
    updated=$(jq --argjson remove "${managed_tag_ids_json}" --argjson add "${add_json}" \
        '.tags = ([.tags[] | select(IN($remove[]) | not)] + $add | unique)' <<< "${series_json}")
    current_tags=$(jq -c '.tags' <<< "${series_json}")
    new_tags=$(jq -c '.tags' <<< "${updated}")

    if [[ "${current_tags}" == "${new_tags}" ]]; then
        echo "  No changes needed for ${title} (${sid})"
        return
    fi

    local tag_labels
    tag_labels=$(jq -r --argjson ids "${add_json}" \
        '[.[] | select(.id as $i | $ids | index($i)) | .label] | join(", ")' <<< "${tags}")
    echo "  Tagging ${title} (${sid}) with: ${tag_labels:-none}"
    api_call -X PUT --data-binary "${updated}" \
        "${SONARR_API_URL}/series/${sid}" >/dev/null
}

# If called with a specific series (on import), tag just that series.
# Otherwise, fetch all series once and process sequentially.
if [[ -n "${SERIES_ID}" ]]; then
    tag_series "${SERIES_ID}"
else
    echo "No series ID provided, processing all series..."
    all_series=$(api_call "${SONARR_API_URL}/series")
    count=$(jq 'length' <<< "${all_series}")

    for (( i = 0; i < count; i++ )); do
        series_json=$(jq -c ".[$i]" <<< "${all_series}")
        sid=$(jq -r '.id' <<< "${series_json}")
        tag_series "${sid}" "${series_json}"
    done
    echo "Finished processing ${count} series"
fi
