# k3sup

> *Note*: this document is a work in progress

## Install k3s with k3sup

```bash
k3sup install --ip "192.168.42.11" \
    --k3s-version "v1.17.0+k3s.1" \
    --user "devin" \
    --k3s-extra-args "--docker --no-deploy servicelb --no-deploy traefik --no-deploy metrics-server"

# k3s-worker-a
k3sup join --ip "192.168.42.12" \
    --server-ip "192.168.42.11" \
    --k3s-version "v1.17.0+k3s.1" \
    --user "devin" \
    --k3s-extra-args "--docker"

# k3s-worker-b
k3sup join --ip "192.168.42.13" \
    --server-ip "192.168.42.11" \
    --k3s-version "v1.17.0+k3s.1" \
    --user "devin" \
    --k3s-extra-args "--docker"

# k3s-worker-c
k3sup join --ip "192.168.42.14" \
    --server-ip "192.168.42.11" \
    --k3s-version "v1.17.0+k3s.1" \
    --user "devin" \
    --k3s-extra-args "--docker"

# k3s-worker-d
k3sup join --ip "192.168.42.15" \
    --server-ip "192.168.42.11" \
    --k3s-version "v1.17.0+k3s.1" \
    --user "devin" \
    --k3s-extra-args "--docker"

# k3s-worker-e
k3sup join --ip "192.168.42.16" \
    --server-ip "192.168.42.11" \
    --k3s-version "v1.17.0+k3s.1" \
    --user "devin" \
    --k3s-extra-args "--docker"

# Don't run anything on the master node
kubectl taint nodes k3s-master k3s-controlplane=true:NoExecute

# Label worker nodes as such
kubectl label node k3s-worker-a node-role.kubernetes.io/worker=worker && \
kubectl label node k3s-worker-b node-role.kubernetes.io/worker=worker && \
kubectl label node k3s-worker-c node-role.kubernetes.io/worker=worker && \
kubectl label node k3s-worker-d node-role.kubernetes.io/worker=worker && \
kubectl label node k3s-worker-e node-role.kubernetes.io/worker=worker

# Label worker nodes that can accept Intel GPU
kubectl label nodes k3s-worker-a homelab.gpu/type=intel && \
kubectl label nodes k3s-worker-b homelab.gpu/type=intel && \
kubectl label nodes k3s-worker-c homelab.gpu/type=intel && \
kubectl label nodes k3s-worker-d homelab.gpu/type=intel && \
kubectl label nodes k3s-worker-e homelab.gpu/type=intel
```
