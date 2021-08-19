#!/usr/bin/env sh

set -o nounset
set -o errexit

if [ -z "$UPTIMEROBOT_HEARTBEAT_URL" ]; then
    printf "%s - Yikes - Missing UPTIMEROBOT_HEARTBEAT_URL environment variable" "$(date -u)"
    exit 0
fi

status_code=$(curl --connect-timeout 10 --max-time 30 -I -s -o /dev/null -w '%{http_code}' "$UPTIMEROBOT_HEARTBEAT_URL")
if [ "${status_code}" != "200" ]; then
    printf "%s - Yikes - Heartbeat request failed, http code: %s" "$(date -u)" "$status_code"
    exit 0
fi

printf "%s - Success - Heartbeat request received and processed successfully" "$(date -u)"
