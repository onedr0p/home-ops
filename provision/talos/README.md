# Sidero

My personalized rough guide taken from the [official docs](https://www.sidero.dev/docs/v0.3/guides/sidero-on-rpi4/).

## Installing Talos

Prepare the SD card with the Talos RPi4 image, and boot the RPi4. Talos should drop into maintenance mode printing the acquired IP address. Record the IP address as the environment variable `SIDERO_ENDPOINT`:

```sh
set -gx SIDERO_ENDPOINT 192.168.42.179
```

> Note: it makes sense to transform DHCP lease for RPi4 into a static reservation so that RPi4 always has the same IP address.

Generate Talos machine configuration for a single-node cluster:

```sh
talosctl gen config \
    --config-patch='[{"op": "add", "path": "/cluster/allowSchedulingOnMasters", "value": true},{"op": "replace", "path": "/machine/install/disk", "value": "/dev/sda"}]' \
    sidero https://$SIDERO_ENDPOINT:6443/
```

In `controlplane.yaml` uncomment and change all Kubernetes images to use `v1.21.5` and talos image to `v0.13.0`

Submit the generated configuration to Talos:

```sh
talosctl apply-config --insecure -n $SIDERO_ENDPOINT -f controlplane.yaml
```

Merge client configuration `talosconfig` into default `~/.talos/config` location:

```sh
talosctl config merge talosconfig
```

Update default endpoint and nodes:

```sh
talosctl config endpoints $SIDERO_ENDPOINT
talosctl config nodes $SIDERO_ENDPOINT
```

You can verify that Talos has booted by running:

```sh
talosctl version
```

Bootstrap the etcd cluster:

```sh
talosctl bootstrap
```

Fetch the `kubeconfig` from the cluster with:

```sh
talosctl kubeconfig
```

You can watch the bootstrap progress by running:

```sh
talosctl dmesg -f
```

Once Talos prints `[talos] boot sequence: done`, Kubernetes should be up:

```sh
kubectl get nodes
```

## Installing Sidero

Install Sidero with host network mode, exposing the endpoints on the node's address:

```sh
SIDERO_CONTROLLER_MANAGER_HOST_NETWORK=true \
SIDERO_CONTROLLER_MANAGER_API_ENDPOINT=192.168.42.179 \
./bin/clusterctl init -i sidero -b talos -c talos
```

Watch the progress of installation with:

```sh
watch kubectl get pods -A
```

Patch the deployment to enable host networking:

```sh
kubectl patch deploy -n sidero-system sidero-controller-manager --type='json' -p='[{"op": "add", "path": "/spec/template/spec/hostNetwork", "value": true}]'
```

Verify Sidero installation and network setup with:

```sh
curl -I http://$SIDERO_ENDPOINT:8081/tftp/ipxe.efi
```

Change talos version to `v0.13.0` in the Environment resource:

```sh
k edit environment default
```

## Creating the cluster that's managed by Sidero

Edit and apply server and serverclasses for controlplane and workers

Generate cluster configuration:

```sh
CONTROL_PLANE_SERVERCLASS=nuc-master \
WORKER_SERVERCLASS=nuc-worker \
TALOS_VERSION=v0.13.0 \
KUBERNETES_VERSION=v1.21.5 \
CONTROL_PLANE_PORT=6443 \
CONTROL_PLANE_ENDPOINT=192.168.42.178 \
./bin/clusterctl config cluster cluster-0 -i sidero > cluster-0.yaml
```

## Undocumented

curl "http://192.168.42.179:8081/configdata?uuid=f2f9ac76-e15d-ae11-ae1f-1c697a0ef7ed"

watch k get servers,machines,clusters -o wide

kubectl \
        get talosconfig \
        -l cluster.x-k8s.io/cluster-name=cluster-0 \
        -o jsonpath='{.items[0].status.talosConfig}' \
        > cluster-0-talosconfig.yaml

```
    endpoints:
      - 192.168.42.180
    nodes:
      - 192.168.42.180
      - 192.168.42.181
```

talosctl --talosconfig cluster-0-talosconfig.yaml -n 192.168.42.180 kubeconfig ./clusters/

talosctl upgrade --nodes 192.168.42.179 --image ghcr.io/talos-systems/installer:v0.13.0 --force --preserve=true
