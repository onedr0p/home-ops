# calico metrics

## calico-node

```sh
calicoctl patch felixConfiguration default --patch '{"spec":{"prometheusMetricsEnabled": true}}'
```

## calico-typha

Enable Prometheus metrics

```sh
kubectl patch deployment calico-typha -n calico-system --type='json' -p '[
  {"op": "add", "path": "/spec/template/spec/containers/0/env/-",
    "value": {
      "name":"TYPHA_PROMETHEUSMETRICSENABLED","value":"true"
    }
  },
  {"op": "add", "path": "/spec/template/spec/containers/0/env/-",
    "value": {
      "name":"TYPHA_PROMETHEUSMETRICSPORT","value":"9092"
    }
  }
]' \
--dry-run=client -o yaml
```

Expose the metric port

```sh
kubectl patch deployment calico-typha -n calico-system --type='json' -p '[
  {"op": "add", "path": "/spec/template/spec/containers/0/ports/-",
    "value": {
      "containerPort": 9092,
      "name": "http-metrics",
      "protocol": "TCP"
    }
  }
]' \
--dry-run=client -o yaml
```

## calico-kube-controllers

```sh
calicoctl patch kubecontrollersconfiguration default --patch '{"spec":{"prometheusMetricsPort": 9095}}'
```

Expose the metric port

```sh
kubectl patch deployment calico-kube-controllers -n calico-system -p '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "calico-kube-controllers",
          "ports": [{
            "containerPort": 9095,
            "name": "http-metrics",
            "protocol": "TCP"
          }]
        }]
      }
    }
  }
}' \
--dry-run=client -o yaml
```
