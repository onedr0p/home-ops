#!/usr/bin/env bash
export ANSIBLE_CONFIG=./ansible.cfg
ansible-playbook -i hosts.yaml playbooks/poweroff.yaml