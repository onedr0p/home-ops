#!/bin/bash

# qBittorrent settings > 'Run external program on torrent finished'
# /scripts/completed.sh "%F" "%G" "cross-seed-api-key"

/bin/chmod -R 750 "$1"

if [[ "$2" == *"force-cross-seed"* ]]; then
    printf "Searching cross-seed for '%s' with tags '%s'\n" "$1" "$2"
    /usr/bin/curl \
        --silent \
        --connect-timeout 5 \
        --max-time 10 \
        --retry 5 \
        --retry-delay 0 \
        --retry-max-time 40 \
        --request POST \
        --data-urlencode "path=$1" \
        --header "X-Api-Key: $3" \
        http://cross-seed.default.svc.cluster.local/api/webhook
else
    printf "Skipping cross-seed check for '%s' with tags '%s'\n" "$1" "$2"
fi

exit 0
