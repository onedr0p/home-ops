# Ansible

> *Note*: this document is a work in progress

## Run playbook

```bash
env ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook \
    -i ansible/inventory \
    ansible/playbook.yml --ask-become-pass
```
