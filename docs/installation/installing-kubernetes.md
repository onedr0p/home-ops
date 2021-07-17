# Installing Kubernetes

!!! info "Update Ansible inventory configuration and run the `k3s-install` playbook"

```sh
ansible-playbook -i ansible/inventory/home-cluster/hosts.yml ansible/playbooks/kubernetes/k3s-prepare.yml
```
