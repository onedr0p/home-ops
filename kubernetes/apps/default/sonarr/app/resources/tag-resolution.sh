#!/usr/bin/env bash
set -euo pipefail

EVENT_TYPE="${sonarr_eventtype:-}"
SERIES_ID="${sonarr_series_id:-}"

[[ -z "${EVENT_TYPE}" || "${EVENT_TYPE}" == "Download" || "${EVENT_TYPE}" == "EpisodeFileDelete" ]] || exit 0

: "${SONARR__AUTH__APIKEY:?API key required}"
: "${SONARR__SERVER__PORT:?Server port required}"

readonly SONARR_API_URL="http://localhost:${SONARR__SERVER__PORT}/api/v3"

readonly TAG_PREFIX="resolution:"

api_call() {
    curl -fsSL --max-time 30 \
        --header "Content-Type: application/json" \
        --header "X-Api-Key: ${SONARR__AUTH__APIKEY}" \
        "$@"
}

tags=$(api_call "${SONARR_API_URL}/tag")

refresh_managed_ids() {
    managed_tag_ids_json=$(jq -c --arg pfx "${TAG_PREFIX}" \
        '[.[] | select(.label | startswith($pfx)) | .id]' <<< "${tags}")
}
refresh_managed_ids

# Returns through REPLY because a command substitution would lose the tags cache refresh in its subshell.
ensure_tag() {
    local label="$1"
    REPLY=$(jq -r --arg l "${label}" '.[] | select(.label == $l) | .id' <<< "${tags}")
    if [[ -z "${REPLY}" ]]; then
        REPLY=$(api_call -X POST --data-binary "{\"label\":\"${label}\"}" \
            "${SONARR_API_URL}/tag" | jq -r '.id')
        tags=$(api_call "${SONARR_API_URL}/tag")
        refresh_managed_ids
    fi
}

tag_series() {
    local sid="$1"
    local series_json="${2:-}"

    mapfile -t resolutions < <(
        api_call "${SONARR_API_URL}/episodefile?seriesId=${sid}" \
            | jq -r '[.[].quality.quality.resolution] | unique | .[] | select(. > 0) | "\(.)p"'
    )

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

    if [[ -z "${series_json}" ]]; then
        series_json=$(api_call "${SONARR_API_URL}/series/${sid}")
    fi

    local title
    title=$(jq -r '.title' <<< "${series_json}")
    echo "Processing ${title} (${sid})..."

    # Replaces the managed resolution: tags and keeps every other tag on the series.
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
