# docker-registry

## why?

I set up a local registry to cache docker images, as of now the registry is running in my cluster. This is useful for when applications update, it will first check the private docker registry and use that. If the image is not found it will pull it from dockerhub and store it in my private registry.

## how?

The helm release can be viewed [here](./deployments/default/docker-registry/docker-registry.yaml) also be sure your k3s cluster has been configured to use that registry.

Each node *must* be configured with the file `/etc/rancher/k3s/registries.yaml` on the host:

```yaml
mirrors:
  docker.io:
    endpoint:
      - "http://192.168.42.120:5000"
  192.168.42.120:5000:
    endpoint:
      - "http://192.168.42.120:5000"
```

:rocket:
