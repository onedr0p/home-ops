#!/usr/bin/env zx
$.verbose = false
const response = await fetch('https://api.cloudflare.com/client/v4/ips')
const body = await response.json()
const ips = body.result.ipv4_cidrs.concat(body.result.ipv6_cidrs);
echo(ips.join("\\,"))
