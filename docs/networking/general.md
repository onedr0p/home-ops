# Networking

{% import 'links.jinja2' as links %}

My current cluster-internal networking is implemented by {{ links.external('calico') }}.

| Name                        | CIDR              |
| --------------------------- | ----------------- |
| Management                  | `192.168.1.0/24`  |
| Servers                     | `192.168.42.0/24` |
| k8s external services (BGP) | `192.168.69.0/24` |
| k8s pods                    | `10.69.0.0/16`    |
| k8s services                | `10.96.0.0/16`    |

## Running high-available control-plane

!!! warning
    Due to the way that BGP works, a node can only set up a single BGP connection to the router. This mean kube-vip and Calico services must not be running on the same node.

In order to expose my control-plane on a loadbalanced IP address, I have deployed {{ links.external('kube-vip') }} via static pods on my k8s masters.
It is configured to expose a load balanced IP address over BGP.

## Exposing services on their own IP address

!!! warning
    Currently when using BGP on Opnsense, services do not get properly load balanced. This is due to Opnsense not supporting multipath (ECMP) in the BSD kernel.

Most (http/https) traffic enters my cluster through an Ingress controller. For situations where this is not desirable (e.g. MQTT traffic) or when I need a fixed IP reachable from outside the cluster (e.g. to use in combination with port forwarding) I use {{ links.external('calico') }} configured with BGP.

Using this setup I can define a Service to use a Load Balancer with `externalIPs`, and it will be exposed on my network on that given IP address.

### Mixed-protocol services

I have enabled the `MixedProtocolLBService=true` feature-gate on my cluster. This means that I can combine UDP and TCP ports on the same Service.
