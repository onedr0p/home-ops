#!/usr/bin/env bash

printf "Cleaning subtitles for '%s' ...\n" "$1"
python3 /add-ons/subcleaner/subcleaner.py "$1" -s

case $1 in
    *Movies*) section="4";;
    *Television*) section="5";;
esac

if [[ -n "${section}" ]]; then
    printf "Refreshing Plex section '%s' for '%s' ...\n" "${section}" "$(dirname "$1")"
    /usr/bin/curl -X PUT -G \
        --data-urlencode "path=$(dirname "$1")" \
        --data-urlencode "X-Plex-Token=$2" \
            "http://plex.default.svc.cluster.local:32400/library/sections/${section}/refresh"
fi
