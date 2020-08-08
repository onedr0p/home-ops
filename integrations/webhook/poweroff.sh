#!/usr/bin/env bash

# webhook -hooks integrations/webhook/hooks.json -debug -verbose
export ANSIBLE_CONFIG=./ansible.cfg
ansible-playbook -i hosts.yaml playbooks/poweroff.yaml