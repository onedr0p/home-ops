#!/usr/bin/env bash
set -euo pipefail

case "${sonarr_eventtype:-}" in
    "" | Download | EpisodeFileDelete) ;;
    *) exit 0 ;;
esac

: "${SONARR__AUTH__APIKEY:?API key required}"
: "${SONARR__SERVER__PORT:?Server port required}"

readonly API_URL="http://localhost:${SONARR__SERVER__PORT}/api/v5"
# Sonarr rejects tag labels with characters other than a-z, 0-9 and -
readonly TAG_PREFIX="resolution-"

api() {
    curl -fsS --max-time 30 \
        --header "Content-Type: application/json" \
        --header "X-Api-Key: ${SONARR__AUTH__APIKEY}" \
        "$@"
}

exec {lock}> /tmp/tag-resolution.lock
flock "${lock}"

series=$(api "${API_URL}/series${sonarr_series_id:+/${sonarr_series_id}}" | jq -c --arg prefix "${TAG_PREFIX}" '
    if type == "object" then [.] end
    | map({id, tags, labels: [.statistics.episodeFileQualities[]?.resolution | select(. > 0) | "\($prefix)\(.)p"]})
')

tags=$(api "${API_URL}/tag" | jq -c --arg prefix "${TAG_PREFIX}" '
    map(select(.label | startswith($prefix)))
')

labels=$(jq -r --argjson tags "${tags}" '
    [.[].labels[], $tags[].label] | unique[]
' <<< "${series}")

for label in ${labels}; do
    tag_id=$(jq --arg label "${label}" '.[] | select(.label == $label) | .id' <<< "${tags}")
    if [[ -z "${tag_id}" ]]; then
        tag_id=$(api --request POST --data "{\"label\":\"${label}\"}" "${API_URL}/tag" | jq '.id')
    fi

    jq -c --arg label "${label}" --argjson tag "${tag_id}" '
        def has_files: any(.labels[]; . == $label);
        def has_tag: any(.tags[]; . == $tag);

        {applyTags: "add", tags: [$tag], seriesIds: map(select(has_files and (has_tag | not)) | .id)},
        {applyTags: "remove", tags: [$tag], seriesIds: map(select(has_tag and (has_files | not)) | .id)}
        | select(.seriesIds != [])
    ' <<< "${series}" | while IFS= read -r edit; do
        echo "${label}: ${edit}"
        api --request PUT --data "${edit}" "${API_URL}/series/editor" >/dev/null
    done
done
