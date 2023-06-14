#!/bin/bash
/bin/chmod -R 750 "$1"
/usr/bin/curl -X POST --data-urlencode "infoHash=$2" http://localhost:2468/api/webhook
