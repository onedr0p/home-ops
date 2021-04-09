#!/usr/bin/env bash

set -eu

for NS in $(kubectl get ns 2>/dev/null | grep Terminating | cut -f1 -d ' '); do
    kubectl get ns $NS -o json > /tmp/$NS.json
    sed -i '' "s/\"kubernetes\"//g" /tmp/$NS.json
    kubectl replace --raw "/api/v1/namespaces/$NS/finalize" -f /tmp/$NS.json
done
