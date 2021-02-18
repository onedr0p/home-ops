# Ansible

These Ansible Playbooks and Roles are for preparing an Ubuntu 20.04.x OS to play nicely with Kubernetes and standing up k3s ontop of the nodes.

## Commands

Commands to run can be found in my Ansible Taskfile located [here](https://github.com/onedr0p/home-cluster/blob/main/.taskfiles/Taskfile_ansible.yml), e.g.

```bash
# List hosts in my Ansible inventory
task ansible:list

# Ping hosts in my Ansible inventory
task ansible:ping
```
