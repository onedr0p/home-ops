#!/bin/bash
# qBittorrent settings > 'Run external program on torrent finished'
# /scripts/completed.sh "%F"
/bin/chmod -R 750 "$1"
/usr/bin/curl --silent --request POST --data-urlencode "path=$1" http://cross-seed.default.svc.cluster.local:2468/api/webhook
