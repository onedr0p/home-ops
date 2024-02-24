#!/usr/bin/env bash

# Expire all silences in Alertmanager
silence_ids=$(curl -s "https://alertmanager.devbu.io/api/v2/silences?silenced=false&inhibited=false&active=true" | jq -r '.[] | .id')
for id in $silence_ids; do
    echo "Expiring silence ID: ${id}"
    curl -s -X DELETE "https://alertmanager.devbu.io/api/v2/silence/${id}"
done

# Apply silences to Alertmanager
find ./hack/alertmanager -type f -print0 | \
    xargs -0 -I{} \
        curl -H "Content-Type: application/json" -d @{} \
            https://alertmanager.devbu.io/api/v2/silences
