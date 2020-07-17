# k3sup

> *Note*: this document is a work in progress

## Install k3s with k3sup

```bash
k3sup install --ip "192.168.42.11" \
    --k3s-version "v1.18.4+k3s1" \
    --user "devin" \
    --k3s-extra-args "--no-deploy servicelb --no-deploy traefik --no-deploy metrics-server --default-local-storage-path=/dev/shm --flannel-backend=host-gw"

# k3s-worker-a
k3sup join --ip "192.168.42.12" \
    --server-ip "192.168.42.11" \
    --k3s-version "v1.18.4+k3s1" \
    --user "devin"

# k3s-worker-b
k3sup join --ip "192.168.42.13" \
    --server-ip "192.168.42.11" \
    --k3s-version "v1.18.4+k3s1" \
    --user "devin"

# k3s-worker-c
k3sup join --ip "192.168.42.14" \
    --server-ip "192.168.42.11" \
    --k3s-version "v1.18.4+k3s1" \
    --user "devin"

# k3s-worker-d
k3sup join --ip "192.168.42.15" \
    --server-ip "192.168.42.11" \
    --k3s-version "v1.18.4+k3s1" \
    --user "devin"

# k3s-worker-e
k3sup join --ip "192.168.42.16" \
    --server-ip "192.168.42.11" \
    --k3s-version "v1.18.4+k3s1" \
    --user "devin"

# Label worker nodes as such
kubectl label node k3s-worker-a node-role.kubernetes.io/worker=true && \
kubectl label node k3s-worker-b node-role.kubernetes.io/worker=true && \
kubectl label node k3s-worker-c node-role.kubernetes.io/worker=true && \
kubectl label node k3s-worker-d node-role.kubernetes.io/worker=true && \
kubectl label node k3s-worker-e node-role.kubernetes.io/worker=true

# Label worker nodes that Plex should run on
kubectl label node k3s-worker-d homelab.gpu/type=intel && \
kubectl label node k3s-worker-e homelab.gpu/type=intel

# Label nodes as upgrade-able with system-upgrade
kubectl label node k3s-master k3s-upgrade=true && \
kubectl label node k3s-worker-a k3s-upgrade=true && \
kubectl label node k3s-worker-b k3s-upgrade=true && \
kubectl label node k3s-worker-c k3s-upgrade=true && \
kubectl label node k3s-worker-d k3s-upgrade=true && \
kubectl label node k3s-worker-e k3s-upgrade=true
```

## Grab existing kubeconfig

```bash
k3sup install --ip "192.168.42.11" \
    --k3s-version "v1.18.4+k3s1" \
    --user "devin" \
    --skip-install
```
