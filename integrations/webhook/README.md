# webhook

Project to shutdown my servers from a raspberry pi using [alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/), [webhook](https://github.com/adnanh/webhook) and [ansible](https://github.com/ansible/ansible).

## Workflow

1) [snmp_exporter](https://github.com/prometheus/snmp_exporter) sends Prometheus stats about my UPS, one of these stats is time remaining on battery
2) [webhook](https://github.com/adnanh/webhook) is deployed on a raspberry pi outside the cluster
3) [alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/) has rules configured to send a webhook to [webhook](https://github.com/adnanh/webhook) when the battery is less than 15 minutes remaining
4) [webhook](https://github.com/adnanh/webhook) receives this webhook from [alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/) and runs a [ansible](https://github.com/ansible/ansible) playbook to shutdown my k3s cluster and other servers
