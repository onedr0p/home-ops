#!/usr/bin/env bash

set -o nounset
set -o errexit

config_filename="$(date "+%Y%m%d-%H%M%S").xml"
http_request_date=$(date -R)
http_filepath="opnsense-backup/${config_filename}"
sig="PUT\n\ntext/xml\n${http_request_date}\n/${http_filepath}"
http_signature=$(echo -en "${sig}" | openssl sha1 -hmac "${AWS_SECRET_ACCESS_KEY}" -binary | base64)

echo "Download Opnsense config file ..."
curl -fsSL \
    --user "${OPNSENSE_KEY}:${OPNSENSE_SECRET}" \
    --output "${config_filename}" \
    "http://192.168.1.1/api/backup/backup/download"

echo "Upload backup to s3 bucket ..."
curl -fsSL \
    -X PUT -T "${config_filename}" \
    -H "Host: minio.default.svc.cluster.local" \
    -H "Date: ${http_request_date}" \
    -H "Content-Type: text/xml" \
    -H "Authorization: AWS ${AWS_ACCESS_KEY_ID}:${http_signature}" \
    "http://minio.default.svc.cluster.local:9000/${http_filepath}"
