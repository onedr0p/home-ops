# Preparing Nodes

## Install Ubuntu

Download Ubuntu Server 21.04 ISO and flash it to a USB drive, boot the device from the USB drive and install Ubuntu

### Copy over SSH key from the machine running Ansible

```sh
ssh-copy-id ubuntu@192.168.42.10
```

### Configure static IPs

!!! warning "Set a static IP on your nodes or you may run into issues with Alpine containers"

```yaml
# /etc/netplan/00-installer-config.yaml
network:
  ethernets:
    eno1:
      addresses:
      - 192.168.42.10/24
      gateway4: 192.168.42.1
      nameservers:
        addresses:
        - 192.168.1.1
        search: []
  version: 2
```

## Prepare Ubuntu for k8s

!!! info "Update Ansible inventory configuration and run the `ubuntu-prepare` playbook"

```sh
ansible-playbook -i ansible/inventory/home-cluster/hosts.yml ansible/playbooks/kubernetes/ubuntu-prepare.yml
```
