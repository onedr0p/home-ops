#!/usr/bin/env bash

set -eu

for NS in $(kubectl get ns 2>/dev/null | grep Terminating | cut -f1 -d ' '); do
    kubectl get ns $NS -o json > /tmp/$NS.json
    sed -i '' "s/\"kubernetes\"//g" /tmp/$NS.json
    kubectl replace --raw "/api/v1/namespaces/$NS/finalize" -f /tmp/$NS.json
done

# for POD in $(kubectl get runners --all-namespaces); do

#   k -n actions-runner-system patch runner.actions.summerwind.dev runner-deployment-mbn6l-ts5f4 -p '{"metadata":{"finalizers":[]}}' --type=merge

# done
