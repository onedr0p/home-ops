# kube-prometheus-stack

## NAS Deployments

### node-exporter

```yaml
services:
  node-exporter:
    command:
      - '--path.rootfs=/host/root'
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.udev.data=/host/root/run/udev/data'
      - '--web.listen-address=0.0.0.0:9100'
      - >-
        --collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)
    image: quay.io/prometheus/node-exporter:v1.9.0
    network_mode: host
    ports:
      - '9100:9100'
    restart: always
    volumes:
      - /:/host/root:ro
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
```

### smartctl-exporter

```yaml
services:
  smartctl-exporter:
    command:
      - '--smartctl.device-exclude=nvme0'
    image: quay.io/prometheuscommunity/smartctl-exporter:v0.13.0
    ports:
      - '9633:9633'
    privileged: True
    restart: always
    user: root
```
