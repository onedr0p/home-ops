# Networking

{% import 'links.jinja2' as links %}

Description of how my network is set up.

| Name                        | CIDR              |
| --------------------------- | ----------------- |
| Management                  | `192.168.1.0/24`  |
| Servers                     | `192.168.42.0/24` |
| k8s external services (BGP) | `192.168.69.0/24` |
| k8s pods                    | `10.69.0.0/16`    |
| k8s services                | `10.96.0.0/16`    |

## Nuances with BGP

* With using kube-vip in BGP mode, and Opnsense or pfSense there's currently an issue with ECMP (equal-cost multipath) that does not make this work well. I would advise against using kube-vip in BGP mode when using Opnsense, pfSense or any router software that doesn't implement ECMP.

* If you decide to use kube-vip and calico both in BGP mode, workloads exposing a load balancer `externalIPs` cannot be deployed to the control plane nodes. Simply put the BIRD daemon can only run on one node at a time.

* Currently when using BGP on Opnsense, services with multiple replicas do not get properly load balanced. This is due to Opnsense not supporting ECMP (equal-cost multipath) in the BSD kernel. This will be fixed in Opnsense 22.1.

## Running high-available control-plane

In order to get around the issues above with Opnsense I have installed and configured the HA Proxy add-on in Opnsense. This is the load balancer for my Kubernetes control plane. Another alternative is to run kube-vip and metallb in ARP mode and forget about BGP.

## Exposing services on their own IP address

Most HTTP or HTTPS traffic enters my cluster through an ingress controller. For situations where this is not desirable (e.g. MQTT traffic) or when I need a fixed IP reachable from outside the cluster (e.g. to use in combination with port forwarding) I use {{ links.external('calico') }} configured with BGP.

Using this setup I can define a service to use a load balancer with `externalIPs`, and it will be exposed on my network on that given IP address.

### Mixed-protocol services

I have enabled the `MixedProtocolLBService=true` feature-gate on my cluster. This means that I can combine the same port with different protocols (UDP and TCP) on the same service.
