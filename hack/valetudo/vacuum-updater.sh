#!/usr/bin/env bash

#
# One-shot script to install/upgrade valetudo, node-exporter and promtail
#

PROJECT_DIR="$(git rev-parse --show-toplevel)"
VACUUM_USER="root"
VACUUM_ADDR="192.168.1.28"
SSH_OPTS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR"

#
# valetudo
#

version="$(curl -sX GET "https://api.github.com/repos/Hypfer/Valetudo/releases/latest" | jq --raw-output '.tag_name')"
echo "*** Downloading Valetudo... ***"
curl -fsSL -o "/tmp/valetudo" \
    "https://github.com/Hypfer/Valetudo/releases/download/${version}/valetudo-armv7"

ssh "${SSH_OPTS}" -T "${VACUUM_USER}@${VACUUM_ADDR}" <<'EOL'
    echo "*** Stopping Valetudo... ***"
    /etc/init/S11valetudo stop > /dev/null 2>&1
    sleep 10
EOL

echo "*** Copying Valetudo to the Vacuum... ***"
scp "${SSH_OPTS}" -q \
    /tmp/valetudo \
    "${VACUUM_USER}@${VACUUM_ADDR}:/mnt/data/valetudo/valetudo"

ssh "${SSH_OPTS}" -T "${VACUUM_USER}@${VACUUM_ADDR}" <<'EOL'
    echo "*** Remove Valetudo... ***"
    rm /usr/local/bin/valetudo
    echo "*** Move Valetudo... ***"
    mv /mnt/data/valetudo/valetudo /usr/local/bin/valetudo
    echo "*** Make Valetudo Executable... ***"
    chmod +x /usr/local/bin/valetudo
    echo "*** Starting Valetudo... ***"
    /etc/init/S11valetudo start > /dev/null 2>&1
EOL

#
# node_exporter
#

version="$(curl -sX GET "https://api.github.com/repos/prometheus/node_exporter/releases/latest" | jq --raw-output '.tag_name' | sed '1s/^.//')"
echo "*** Downloading node_exporter... ***"
curl -fsSL -o "/tmp/node_exporter.tar.gz" \
    "https://github.com/prometheus/node_exporter/releases/download/v${version}/node_exporter-${version}.linux-armv7.tar.gz"

echo "*** Extracting node_exporter ... ***"
tar zxf /tmp/node_exporter.tar.gz --strip-components=1 -C /tmp

echo "*** Stopping node_exporter... ***"
ssh "${SSH_OPTS}" -T "${VACUUM_USER}@${VACUUM_ADDR}" <<'EOL'
    /etc/init/S11node_exporter stop > /dev/null 2>&1
    sleep 10
EOL

echo "*** Copying node_exporter to the Vacuum... ***"
scp "${SSH_OPTS}" -q \
    /tmp/node_exporter \
    "${VACUUM_USER}@${VACUUM_ADDR}:/mnt/data/node_exporter/node_exporter"

echo "*** Copying node_exporter init script to the Vacuum... ***"
scp "${SSH_OPTS}" -q \
    "${PROJECT_DIR}/hack/valetudo/S11node_exporter" \
    "${VACUUM_USER}@${VACUUM_ADDR}:/etc/init/S11node_exporter"

ssh "${SSH_OPTS}" -T "${VACUUM_USER}@${VACUUM_ADDR}" <<'EOL'
    echo "*** Make node_exporter Executable... ***"
    chmod +x /mnt/data/node_exporter/node_exporter
    echo "*** Starting node_exporter... ***"
    /etc/init/S11node_exporter start > /dev/null 2>&1
EOL

#
# promtail
#

version="$(curl -sX GET "https://api.github.com/repos/grafana/loki/releases/latest" | jq --raw-output '.tag_name')"
echo "*** Downloading Promtail... ***"
curl -fsSL -o "/tmp/promtail.zip" \
    "https://github.com/grafana/loki/releases/download/${version}/promtail-linux-arm.zip"

echo "*** Extracting Promtail ... ***"
unzip -q -o /tmp/promtail.zip -d /tmp

echo "*** Stopping Promtail... ***"
ssh "${SSH_OPTS}" -T "${VACUUM_USER}@${VACUUM_ADDR}" <<'EOL'
    /etc/init/S11promtail stop > /dev/null 2>&1
    sleep 60
EOL

echo "*** Copying Promtail to the Vacuum... ***"
scp "${SSH_OPTS}" -q \
    /tmp/promtail-linux-arm \
    "${VACUUM_USER}@${VACUUM_ADDR}:/mnt/data/promtail/promtail"

echo "*** Copying Promtail init script to the Vacuum... ***"
scp "${SSH_OPTS}" -q \
    "${PROJECT_DIR}/hack/valetudo/S11promtail" \
    "${VACUUM_USER}@${VACUUM_ADDR}:/etc/init/S11promtail"

ssh "${SSH_OPTS}" -T "${VACUUM_USER}@${VACUUM_ADDR}" <<'EOL'
    echo "*** Make Promtail Executable... ***"
    chmod +x /mnt/data/promtail/promtail
    echo "*** Starting Promtail... ***"
    /etc/init/S11promtail start > /dev/null 2>&1
EOL
