# calico metrics

## calico-node

```sh
calicoctl patch felixConfiguration default  --patch '{"spec":{"prometheusMetricsEnabled": true}}'
kubectl -n calico-system edit ds calico-node
```

Under `spec.template.spec.containers`:

```yaml
# ...
ports:
- containerPort: 9091
  name: http-metrics
  protocol: TCP
# ...
```

## calico-typha

```sh
kubectl -n calico-system edit deployment calico-typha
```

Under `spec.template.spec.containers`:

```yaml
# ...
- env:
  - name: TYPHA_PROMETHEUSMETRICSENABLED
    value: "true"
  - name: TYPHA_PROMETHEUSMETRICSPORT
    value: "9092"
# ...
ports:
- containerPort: 9092
  name: http-metrics
  protocol: TCP
# ...
```

## calico-kube-controllers

This is not working I am unable to patch `kubecontrollersconfiguration` with the prometheus port

```sh
calicoctl patch kubecontrollersconfiguration default --patch '{"spec":{"prometheusMetricsPort": 9094}}'
kubectl -n calico-system edit deployment calico-kube-controllers
```

Under `spec.template.spec.containers`:

```yaml
# ...
ports:
- containerPort: 9094
  name: http-metrics
  protocol: TCP
# ...
```
