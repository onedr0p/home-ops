#!/usr/bin/env bash

# sshpass, be aware this is not a very secure method
# use with caution
# MacOS: https://gist.github.com/arunoda/7790979
# Ubuntu: sudo apt-get install sshpass
# Windows: https://stackoverflow.com/a/43068475/10496442

export REPO_ROOT
REPO_ROOT=$(git rev-parse --show-toplevel)

need() {
    which "$1" &>/dev/null || die "Binary '$1' is missing but required"
}

need "ssh"
need "sshpass"

if [ "$(uname)" == "Darwin" ]; then
  set -a
  . "${REPO_ROOT}/secrets/.secrets.env"
  set +a
else
  . "${REPO_ROOT}/secrets/.secrets.env"
fi

message() {
  echo -e "\n######################################################################"
  echo "# $1"
  echo "######################################################################"
}

ESXI_HOSTS=(esxi-a.lan esxi-b.lan esxi-c.lan esxi-d.lan esxi-e.lan esxi-f.lan esxi-g.lan)

for host in "${ESXI_HOSTS[@]}"; do
  message "Gracefully ending VMs and shutting down ESXi host ${host}"
  sshpass -p ${ESXI_PASSWORD} ssh ${ESXI_USERNAME}@${host} "/sbin/shutdown.sh && /sbin/poweroff"
done

message "All done!"