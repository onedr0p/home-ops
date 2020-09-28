# docker-registry

## why?

I set up a local registry to cache docker images, as of now the registry is running in my cluster. This is useful for when applications update, it will first check the private docker registry and use that. If the image is not found it will pull it from dockerhub and store it in my private registry.

## how?

The helm release can be viewed [here](./deployments/default/docker-registry/docker-registry.yaml) also be sure your k3s cluster has been configured to use that registry.

Each node **must** be configured with the file `/etc/rancher/k3s/registries.yaml` on the host, where the IP:PORT is the location of your registry.

```yaml
mirrors:
  docker.io:
    endpoint:
      - "http://192.168.42.120:5000"
  192.168.42.120:5000:
    endpoint:
      - "http://192.168.42.120:5000"
```

After you set that, restart k3s server and all the agents.

```bash
# master node
sudo systemctl restart k3s
# worker nodes
sudo systemctl restart k3s-agent
```

:rocket:
