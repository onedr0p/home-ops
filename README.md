# k3s-gitops

Will clean up docs at some point :)

## Cluster Nodes

|Device|Node Type|Hostname|CPU|Ram|Disk|
|---|---|---|---|---|---|
|RPi4|Master|k3s-master-a|4000m|4GB|32GB SD|
|RPi4|Master|k3s-master-b|4000m|4GB|32GB SD|
|RPi4|Master|k3s-master-c|4000m|4GB|32GB SD|
|Intel-NUC8i7BEH|Worker|k3s-worker-a|8000m|64GB|500GB NVMe|
|Odroid-H2|Storage|k3s-storage-a|4000m|32GB|1TB NVMe|
|Odroid-H2|Storage|k3s-storage-b|4000m|32GB|1TB NVMe|
|Odroid-H2|Storage|k3s-storage-c|4000m|32GB|1TB NVMe|

## Install HA Master on RPis

```bash
k3sup install --ip "192.168.42.23" \
    --k3s-version "v1.0.1" \
    --user "devin" \
    --k3s-extra-args "--node-taint k3s-controlplane=true:NoExecute --no-deploy servicelb --no-deploy traefik --no-deploy local-storage --no-deploy metrics-server" \
    --cluster

k3sup join --ip "192.168.42.24" \
    --user "devin" \
    --server-user "devin" \
    --k3s-extra-args "--node-taint k3s-controlplane=true:NoExecute --no-deploy servicelb --no-deploy traefik --no-deploy local-storage --no-deploy metrics-server" \
    --server-ip "192.168.42.23" \
    --server

k3sup join --ip "192.168.42.25" \
    --user "devin" \
    --server-user "devin" \
    --k3s-extra-args "--node-taint k3s-controlplane=true:NoExecute --no-deploy servicelb --no-deploy traefik --no-deploy local-storage --no-deploy metrics-server" \
    --server-ip "192.168.42.23" \
    --server

k3sup join --ip "192.168.42.40" \
    --server-ip "192.168.42.23" \
    --k3s-version "v1.0.1" \
    --user "devin"
```
