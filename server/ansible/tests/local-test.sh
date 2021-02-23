#!/usr/bin/env bash
set -eu

git_root=$(git rev-parse --show-toplevel)
ansible_root="${git_root}/server/ansible"
inventory="${ansible_root}/inventory/e2e/hosts.yml"
# tests_root="${ansible_root}/tests"

export ANSIBLE_CONFIG="${ansible_root}/ansible.cfg"

# Install deps
npm install

# Switch to the right stack
pulumi stack select single-control-plane

# Destroy cloud resouces
pulumi destroy --yes || true

# Create cloud resouces
pulumi up --yes

# Get inventory file
pulumi stack output --json | yq eval -P - > "${inventory}"
cat "${inventory}"

# Install Ansible Galaxy roles
ansible-galaxy install -r "${ansible_root}/requirements.yml"

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

# kubectl --kubeconfig /tmp/kubeconfig get nodes -o wide
# kubectl --kubeconfig /tmp/kubeconfig -n kube-system wait pod --label app=coredns --for=condition=ready
# kubectl --kubeconfig /tmp/kubeconfig -n kube-system wait deployment.apps/coredns --for=condition=available --timeout=2m
# kubectl --kubeconfig /tmp/kubeconfig -n tigera-operator wait deployment.apps/tigera-operator --for=condition=available --timeout=2m
# kubectl --kubeconfig /tmp/kubeconfig -n calico-system wait daemonset.apps/calico-node --for=condition=available --timeout=2m
# kubectl --kubeconfig /tmp/kubeconfig -n calico-system wait deployment.apps/calico-typha --for=condition=available --timeout=2m
# kubectl --kubeconfig /tmp/kubeconfig -n calico-system wait deployment.apps/calico-kube-controllers --for=condition=available --timeout=2m

# Destroy cloud resouces
# pulumi destroy --yes

# rm -f "${inventory}"
