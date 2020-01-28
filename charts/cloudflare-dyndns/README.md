# Dynamic DNS using Cloudflare's DNS Services

A script that pushes the public IP address of the running machine to Cloudflare's DNS API's. It requires an existing A record to update.

## TL;DR;

```console
$ helm repo add billimek https://billimek.com/billimek-charts/
$ helm install billimek/cloudflare-dyndns
```

## Introduction

This code is adopted from [this original repo](https://github.com/hotio/docker-cloudflare-ddns)

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release billimek/cloudflare-dyndns
```

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
$ helm delete my-release --purge
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following tables lists the configurable parameters of the Sentry chart and their default values.

| Parameter                            | Description                                  | Default                                                    |
| -------------------------------      | -------------------------------              | ---------------------------------------------------------- |
| `image.repository`                   | cloudflare-dyndns image                            | `hotio/cloudflare-ddns`                        |
| `image.tag`                          | cloudflare-dyndns image tag                        | `latest`                                           |
| `image.pullPolicy`                   | cloudflare-dyndns image pull policy                | `Always`                                           |
| `cloudflare.user`                | The username of your Cloudflare account, should be your email address. | ``                                               |
| `cloudflare.token`                | The token you generated in Cloudflare's API settings. | ``                                               |
| `cloudflare.zones`               | The domain(s) you wish to update, separated by `;` | ``                          |
| `cloudflare.hosts`                 | The subdomain(s) you wish to update, separated by `;` | ``             |
| `cloudflare.record_types`                 | The record types to update, separated by `;` | ``             |
| `cloudflare.detection_mode`                 | Source to query for public IP | `dig-google.com`             |
| `cloudflare.log_level`                 | Verbosity of the logs printed to stdout/stderr | `1`             |
| `cloudflare.sleep_interval`       |  Polling time in seconds                             | `300`                                              |


Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
helm install --name my-release \
  --set config.cloudflare.token=thisismyapikey \
    billimek/cloudflare-dyndns
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
helm install --name my-release -f values.yaml billimek/cloudflare-dyndns
```

Read through the [values.yaml](https://github.com/billimek/billimek-charts/blob/master/charts/cloudflare-dyndns/values.yaml) file. It has several commented out suggested values.
