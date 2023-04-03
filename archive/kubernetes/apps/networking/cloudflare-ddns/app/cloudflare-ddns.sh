#!/usr/bin/env bash

set -o nounset
set -o errexit

current_ipv4="$(curl -s https://ipv4.icanhazip.com/)"
zone_id=$(curl -s -X GET \
    "https://api.cloudflare.com/client/v4/zones?name=${CLOUDFLARE_RECORD_NAME#*.}&status=active" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_APIKEY}" \
    -H "Content-Type: application/json" \
        | jq --raw-output ".result[0] | .id"
)
record_ipv4=$(curl -s -X GET \
    "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?name=${CLOUDFLARE_RECORD_NAME}&type=A" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_APIKEY}" \
    -H "Content-Type: application/json" \
)
old_ip4=$(echo "$record_ipv4" | jq --raw-output '.result[0] | .content')
if [[ "${current_ipv4}" == "${old_ip4}" ]]; then
    printf "%s - IP Address '%s' has not changed" "$(date -u)" "${current_ipv4}"
    exit 0
fi
record_ipv4_identifier="$(echo "$record_ipv4" | jq --raw-output '.result[0] | .id')"
update_ipv4=$(curl -s -X PUT \
    "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${record_ipv4_identifier}" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "X-Auth-Key: ${CLOUDFLARE_APIKEY}" \
    -H "Content-Type: application/json" \
    --data "{\"id\":\"${zone_id}\",\"type\":\"A\",\"proxied\":true,\"name\":\"${CLOUDFLARE_RECORD_NAME}\",\"content\":\"${current_ipv4}\"}" \
)
if [[ "$(echo "$update_ipv4" | jq --raw-output '.success')" == "true" ]]; then
    printf "%s - Success - IP Address '%s' has been updated" "$(date -u)" "${current_ipv4}"
    exit 0
else
    printf "%s - Yikes - Updating IP Address '%s' has failed" "$(date -u)" "${current_ipv4}"
    exit 1
fi
