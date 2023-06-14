#!/bin/bash

TORRENT_PATH="${1}"
TORRENT_NAME="${2}"
/bin/chmod -R 750 "${TORRENT_PATH}"
/usr/bin/curl -X POST --data-urlencode "name=${TORRENT_NAME}" http://localhost:2468/api/webhook
