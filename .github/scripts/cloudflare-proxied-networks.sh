#!/usr/bin/env bash

# Get all local networks
# ipv4_rfc1918='[ "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16" ]'

# Get all cloudflare ipv4 ranges in an array
ipv4_cloudflare="$(curl -s https://www.cloudflare.com/ips-v4 | jq --raw-input --slurp 'split("\n")')"
if [[ -z "${ipv4_cloudflare}" ]]; then
    exit 1
fi

# Get all cloudflare ipv6 ranges in an array
ipv6_cloudflare="$(curl -s https://www.cloudflare.com/ips-v6 | jq --raw-input --slurp 'split("\n")')"
if [[ -z "${ipv6_cloudflare}" ]]; then
    exit 1
fi

# Merge rfc1918 ipv4, cloudflare ipv4, and cloudflare ipv6 ranges into one array
combined=$(jq \
    --argjson ipv4_cloudflare "${ipv4_cloudflare}" \
    --argjson ipv6_cloudflare "${ipv6_cloudflare}" \
    -n '$ipv4_cloudflare + $ipv6_cloudflare' \
)

# Output array as a string with \, as delimiter
echo "${combined}" | jq --raw-output '. | join("\\,")'
