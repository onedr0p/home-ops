#!/usr/bin/env bash

image="${1}"

for i in {1..105}; do
    echo "==== TEST ${i} ===="
    docker pull "${image}"
    docker image rm "${image}"
done
