#!/usr/bin/env bash

# Get all cloudflare ipv4 ranges in an array
ipv4="$(curl -s https://www.cloudflare.com/ips-v4 | jq --raw-input --slurp 'split("\n")')"
if [[ -z "${ipv4}" ]]; then
    exit 1
fi

# Get all cloudflare ipv6 ranges in an array
ipv6="$(curl -s https://www.cloudflare.com/ips-v6 | jq --raw-input --slurp 'split("\n")')"
if [[ -z "${ipv6}" ]]; then
    exit 1
fi

# Merge both cloudflare ipv4 and ipv6 ranges into one array
ipv4ipv6=$(jq \
    --argjson arr1 "$ipv4" \
    --argjson arr2 "$ipv6" \
    -n '$arr1 + $arr2 | sort_by(.)' \
)

# Output array as a string with \, as delimiter
echo "${ipv4ipv6}" | jq --raw-output '. | join("\\,")'
