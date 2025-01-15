#!/usr/bin/env sh

name=$(echo "$1" | awk -F'"localDirectoryName": "' '{print $2}' | awk -F'",' '{print $1}')

wget -q -O/dev/null \
     --post-data "name=${name}&path=${name}" \
     --header="X-API-KEY: ${BETANIN_API_KEY}" \
     --header="User-Agent: notify-beats.sh" \
      "http://${BEETS_HOST}/api/torrents"
