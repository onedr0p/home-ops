#!/usr/bin/env bash

# alertname=CephNodeDiskspaceWarning,device=/dev/sda2
MATCHERS="alertname=CephNodeDiskspaceWarning,device=/dev/sda2"

IFS=',' read -r -a MATCHERS_ARRAY <<< "$MATCHERS"
for matcher in "${MATCHERS_ARRAY[@]}"; do
  IFS='=' read -r -a matcher_array <<< "$matcher"
  name="${matcher_array[0]}"
  value="${matcher_array[1]}"
  matchers+=("$(jo name="${name}" value="${value}" isRegex=false)")
done

curl -X POST https://alertmanager.devbu.io/api/v2/silences \
    -H "Content-Type: application/json" \
    -d "$(jo -p \
            matchers="$(jo -a ${matchers[*]})" \
            startsAt="2000-01-01T00:00:00.000Z" \
            endsAt="2100-01-01T00:00:00.000Z" \
            createdBy="api" \
            comment="Imported Silence" \
            status="$(jo -p state="active")"\
        )"
