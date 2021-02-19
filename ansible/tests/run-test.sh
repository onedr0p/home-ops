#!/usr/bin/env bash
set -eu

project_root=$(git rev-parse --show-toplevel)
ansible_root="${project_root}/ansible"

export ANSIBLE_CONFIG="${ansible_root}/ansible.cfg"

# Install deps
npm install

# Switch to the right stack
pulumi stack select ubuntu-2010

# Destroy cloud resouces
pulumi destroy --yes || true

# Create cloud resouces
pulumi up --yes

# Get inventory file
inventory=$(mktemp --suffix ".yaml")
pulumi stack output --json | yq eval -P - > "${inventory}"
cat "${inventory}"

# Wait for Droplets to come online
while ! ansible all -i "${inventory}" --one-line -m ping &> /dev/null
do
    printf "%c" "."
done

# Run the Ansible Ubuntu prepare playbook
echo "n" | ansible-playbook -i "${inventory}" "${ansible_root}/playbooks/ubuntu/prepare.yml"

# Destroy cloud resouces
pulumi destroy --yes

rm -f "${inventory}"
