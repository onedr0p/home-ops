#!/usr/bin/env bash

#
# One-shot script to install/upgrade valetudo, node-exporter and vector.
# Doing this in Ansible would be way too gluey since the Vacuum doesn't
# have Python installed.
#

VACUUM_USER="root"
VACUUM_ADDR="192.168.1.28"
SSH_OPTS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR"

# renovate: datasource=github-releases depName=Hypfer/Valetudo
VALETUDO_VERSION="2022.05.1"

#
# valetudo
#
echo "*** Downloading Valetudo... ***"
curl -fsSL -o "/tmp/valetudo" \
    "https://github.com/Hypfer/Valetudo/releases/download/${VALETUDO_VERSION}/valetudo-armv7"
ssh "${SSH_OPTS}" -T "${VACUUM_USER}@${VACUUM_ADDR}" <<'EOL'
    echo "*** Stopping Valetudo... ***"
    /etc/init/S11valetudo stop > /dev/null 2>&1
    sleep 10
EOL
echo "*** Copying Valetudo to the Vacuum... ***"
scp -O "${SSH_OPTS}" -q \
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
