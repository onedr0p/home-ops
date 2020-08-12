#!/usr/bin/env bash

# Get Absolute Path of the base repo
export REPO_ROOT=$(git rev-parse --show-toplevel)

# Get Absolute Path of the auto-shutdown directory
export AUTO_SHUTDOWN_ROOT="${REPO_ROOT}/integrations/auto-shutdown"

# Create logs directory
mkdir -p "${REPO_ROOT}/logs"

# Set up log filenames
LOGFILE="${REPO_ROOT}/logs/poweroff-$(date +'%Y.%m.%d-%H.%M.%S')"
rm "${REPO_ROOT}"/logs/poweroff-*.log

# List of k8s nodes
NODES=(k3s-worker-a k3s-worker-b k3s-worker-c k3s-worker-d k3s-worker-e)

# Cordon worker nodes sequentially
for node in "${NODES[@]}"
do
    # echo "${node}" | tee -a "${LOGFILE}-cordon.log"
    kubectl cordon $node 2>&1 | tee -a "${LOGFILE}-cordon.log"
done

# Drain worker nodes concurrently
for node in "${NODES[@]}"
do
    # echo "${node}" | tee -a "${LOGFILE}-drain-${node}.log" &
    kubectl drain $node --ignore-daemonsets --force --grace-period=60 --timeout=120s --delete-local-data 2>&1 | tee -a "${LOGFILE}-drain-${node}.log" &
done

# Wait for nodes to finish draining
sleep 120

# Poweroff hosts
# Order: k3s-workers, k3s-master, nas devices
export ANSIBLE_CONFIG="${AUTO_SHUTDOWN_ROOT}/ansible.cfg"
ansible-playbook -i "${AUTO_SHUTDOWN_ROOT}/ansible-hosts.yaml" "${AUTO_SHUTDOWN_ROOT}/ansible-playbook.yaml" 2>&1 | tee -a "${LOGFILE}-ansible.log"