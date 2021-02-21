#!/usr/bin/env bash
set -eu

project_root=$(git rev-parse --show-toplevel)
ansible_root="${project_root}/ansible"
inventory="${ansible_root}/inventory/e2e/hosts.yml"

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
pulumi stack output --json | yq eval -P - > "${inventory}"
cat "${inventory}"

# Install Ansible Galaxy roles
ansible-galaxy install -r "${ansible_root}/requirements.yml" --force

# Wait for Droplets to come online
while ! ansible all -i "${inventory}" --one-line -m ping &> /dev/null
do
    printf "%c" "."
done

# Run the Ansible Ubuntu prepare playbook
ansible-playbook -i "${inventory}" "${ansible_root}/playbooks/ubuntu/prepare.yml"

# Wait for Droplets to come online
while ! ansible all -i "${inventory}" --one-line -m ping &> /dev/null
do
    printf "%c" "."
done

# Run the Ansible k3s install playbook
ansible-playbook -i "${inventory}" "${ansible_root}/playbooks/k3s/install.yml"

watch kubectl --kubeconfig "/tmp/k3s.yaml" get nodes -o wide

# Destroy cloud resouces
# pulumi destroy --yes

# rm -f "${inventory}"
