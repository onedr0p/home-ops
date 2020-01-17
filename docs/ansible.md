# Ansible

> *Note*: this document is a work in progress

## Provision playbook

```bash
env ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook \
  -i ansible/inventory \
  ansible/playbook.yml --ask-become-pass
```

## Teardown cluster playbook

```bash
env ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook \
  -i ansible/inventory \
  ansible/playbook-k3s-teardown.yml --ask-become-pass
```

## Reset Ceph playbook
