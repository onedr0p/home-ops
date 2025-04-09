#!/usr/bin/env sh

name="$(jq --raw-output '.localDirectoryName' <<< $1)"

wget -q -O/dev/null \
     --post-data "name=${name}&path=${name}" \
     --header="X-API-KEY: ${BETANIN_API_KEY}" \
     --header="User-Agent: slskd/0.0" \
      "http://${BEETS_HOST}/api/torrents"
