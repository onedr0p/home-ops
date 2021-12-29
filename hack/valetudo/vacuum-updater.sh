#!/usr/bin/env bash

#
# One-shot script to install/upgrade valetudo, node-exporter and vector
#

PROJECT_DIR="$(git rev-parse --show-toplevel)"
VACUUM_USER="root"
VACUUM_ADDR="192.168.1.28"
SSH_OPTS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR"

#
# valetudo
#

# TODO: Renovate valetudo version in hack
valetudo_version="2021.12.1"
echo "*** Downloading Valetudo... ***"
curl -fsSL -o "/tmp/valetudo" \
    "https://github.com/Hypfer/Valetudo/releases/download/${valetudo_version}/valetudo-armv7"
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

# TODO: Renovate node_exporter version in hack
node_exporter_version="1.3.1"
echo "*** Downloading node_exporter... ***"
curl -fsSL -o "/tmp/node_exporter.tar.gz" \
    "https://github.com/prometheus/node_exporter/releases/download/v${node_exporter_version}/node_exporter-${node_exporter_version}.linux-armv7.tar.gz"
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
# vector
#

# TODO: Renovate vector version in hack
vector_version="0.19.0"
echo "*** Downloading Vector... ***"
curl -fsSL -o "/tmp/vector.tar.gz" \
    "https://github.com/vectordotdev/vector/releases/download/v${vector_version}/vector-${vector_version}-armv7-unknown-linux-musleabihf.tar.gz"
echo "*** Extracting Vector ... ***"
tar zxf /tmp/vector.tar.gz --strip-components=1 -C /tmp
echo "*** Stopping Vector... ***"
ssh "${SSH_OPTS}" -T "${VACUUM_USER}@${VACUUM_ADDR}" <<'EOL'
    /etc/init/S11vector stop > /dev/null 2>&1
    sleep 10
EOL
echo "*** Copying Vector to the Vacuum... ***"
scp "${SSH_OPTS}" -q \
    /tmp/vector-armv7-unknown-linux-musleabihf/bin/vector \
    "${VACUUM_USER}@${VACUUM_ADDR}:/mnt/data/vector/vector"
echo "*** Copying Vector init script to the Vacuum... ***"
scp "${SSH_OPTS}" -q \
    "${PROJECT_DIR}/hack/valetudo/S11vector" \
    "${VACUUM_USER}@${VACUUM_ADDR}:/etc/init/S11vector"
ssh "${SSH_OPTS}" -T "${VACUUM_USER}@${VACUUM_ADDR}" <<'EOL'
    echo "*** Make Vector Executable... ***"
    chmod +x /mnt/data/vector/vector
    echo "*** Starting Vector... ***"
    /etc/init/S11vector start > /dev/null 2>&1
EOL
