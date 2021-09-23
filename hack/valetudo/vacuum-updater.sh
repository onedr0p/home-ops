#!/usr/bin/env bash

#
# valetudo
#

version="$(curl -sX GET "https://api.github.com/repos/Hypfer/Valetudo/releases/latest" | jq --raw-output '.tag_name')"
echo "*** Downloading Valetudo... ***"
curl -fsSL -o "/tmp/valetudo" \
    "https://github.com/Hypfer/Valetudo/releases/download/${version}/valetudo-armv7"
echo "*** Copying Valetudo to the Vacuum... ***"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q \
    /tmp/valetudo \
    root@192.168.1.28:/mnt/data/valetudo/valetudo

ssh -T root@192.168.1.28 <<'EOL'
    echo "*** Stopping Valetudo... ***"
    /etc/init/S11valetudo stop > /dev/null 2>&1
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
# promtail
#

version="$(curl -sX GET "https://api.github.com/repos/grafana/loki/releases/latest" | jq --raw-output '.tag_name')"
echo "*** Downloading Promtail... ***"
curl -fsSL -o "/tmp/promtail.zip" \
    "https://github.com/grafana/loki/releases/download/${version}/promtail-linux-arm.zip"

echo "*** Extracting Promtail ... ***"
unzip -q -o /tmp/promtail.zip -d /tmp

echo "*** Copying Promtail to the Vacuum... ***"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q \
    /tmp/promtail-linux-arm \
    root@192.168.1.28:/mnt/data/promtail/promtail

echo "*** Copying Promtail init script to the Vacuum... ***"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q \
    ./hack/valetudo/S11promtail \
    root@192.168.1.28:/etc/init/S11promtail

ssh -T root@192.168.1.28 <<'EOL'
    echo "*** Stopping Promtail... ***"
    /etc/init/S11promtail stop > /dev/null 2>&1
    echo "*** Make Promtail Executable... ***"
    chmod +x /mnt/data/promtail/promtail
    echo "*** Starting Promtail... ***"
    /etc/init/S11promtail start > /dev/null 2>&1
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

echo "*** Copying node_exporter to the Vacuum... ***"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q \
    /tmp/node_exporter \
    root@192.168.1.28:/mnt/data/node_exporter/node_exporter

echo "*** Copying node_exporter init script to the Vacuum... ***"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q \
    ./hack/valetudo/S11node_exporter \
    root@192.168.1.28:/etc/init/S11node_exporter

ssh -T root@192.168.1.28 <<'EOL'
    echo "*** Stopping node_exporter... ***"
    /etc/init/S11node_exporter stop > /dev/null 2>&1
    echo "*** Make node_exporter Executable... ***"
    chmod +x /mnt/data/node_exporter/node_exporter
    echo "*** Starting node_exporter... ***"
    /etc/init/S11node_exporter start > /dev/null 2>&1
EOL
