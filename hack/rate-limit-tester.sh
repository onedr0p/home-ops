#!/usr/bin/env bash

image="${1}"

for i in {1..3}; do
    echo "==== TEST ${i} ===="
    docker pull "${image}"
    docker image rm "${image}" --force
done
