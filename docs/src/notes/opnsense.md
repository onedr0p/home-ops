# Opnsense

```admonish warning
I am no longer use Opnsense therefor this document will likely not be updated anymore.
```

## BGP

Instead of using Metallb for L2/L3 load balancer IPs I am using the Kubernetes Calico CNI with BGP which allows me to advertise load balancer IPs directly over BGP. This has some benefits like having equal cost multipath (ECMP) for scaled workloads in my cluster.

1. Routing > BPG | General
    1. `enable` = `true`
    2. `BGP AS Number` = `64512`
    3. `Network` = `192.168.42.0/24` (Subnet your Kubernetes nodes are on)
    4. Save
2. Routing > BGP | Neighbors
    - Add a neighbor for each Kubernetes node
      1. `Enabled` = `true`
      2. `Peer-IP` = `192.168.42.x` (Kubernetes Node IP)
      3. `Remote AS` = `64512`
      4. `Update-Source Interface` = `HOME_SERVER` (VLAN of Kubernetes nodes)
      5. Save
      6. Continue adding neighbors until all your nodes are present
3. Routing > General
    1. `Enable` = `true`
    2. Save
4. System > Settings > Tunables
    1. Add `net.route.multipath` and set the value to `1`
    2. Save
5. Reboot
6. Verify
    1. Routing > Diagnostics | Summary

```admonish warning
Without updating the configuration described in **step 4** the routes from a client will only take a **single path to your Kubernetes workloads** even if they are scaled to more than one.
```

## HAProxy

While kube-vip is very nice for having a API server ready to go and running in your cluster I had issues with mixing layer 2 and layer 3 between Calico in BGP and kube-vip using L2 ARP. You also cannot run Calico in BGP with kube-vip in BGP, they will fight and you will lose. Instead I choose to use Haproxy which you can install from the Opnsense Plugins.

1. Services > HAProxy | Real Servers
    - Add a server for each **master node** in your Kubernetes cluster
      1. `Enabled` = `true`
      2. `Name or Prefix` = `k8s-apiserver-x`
      3. `FQDN or IP` = `192.168.42.x`
      4. `Port` = `6443`
      5. `Verify SSL Certificate` = `false`
      6. Apply/Save
      7. Continue adding servers until all your **master nodes** are present
2. Services > HAProxy | Rules & Checks > Health Monitors
    1. `Name` = `k8s-apiserver-health`
    2. `SSL preferences` = `Force SSL for health checks`
    3. `Port to check` = `6443`
    4. `HTTP method` = `GET`
    5. `Request URI` = `/healthz`
    6. `HTTP version` = `HTTP/1.1`
    7. Apply/Save
3. Services > HAProxy | Virtual Services > Backend Pools
    1. `Enabled` = `true`
    2. `Name` = `k8s-apiserver-be`
    3. `Mode` = `TCP (Layer 4)`
    4. `Servers` = `k8s-apiserver-x` ... (Add one for each server you created. Use TAB key to complete typing each server)
    5. `Source address` = `192.168.1.1` (Your Opnsense IP address)
    6. `Enable Health Checking` = `true`
    7. `Health Monitor` = `k8s-apiserver-health`
    8. Apply/Save
4. Services > HAProxy | Virtual Services > Public Services
    1. `Enabled` = `true`
    2. `Name` = `k8s-apiserver-fe`
    3. `Listen Addresses` = `192.168.1.1:6443` (Your Opnsense IP address. Use TAB key to complete typing a listen address)
    4. `Type` = `TCP`
    5. `Default Backend Pool` = `k8s-apiserver-be`
    6. Apply/Save
5. Services > HAProxy | Settings > Service
    1. `Enable HAProxy` = `true`
    2. Apply/Save
6. Services > HAProxy | Settings > Global Parameters
    1. `Verify SSL Server Certificates` = `disable-verify`
    2. Apply/Save
7. Services > HAProxy | Settings > Default Parameters
    1. `Client Timeout` = `4h`
    2. `Connection Timeout` = `10s`
    3. `Server Timeout` = `4h`
    4. Apply/Save

## Receive Side Scaling (RSS)

RSS is used to distribute packets over CPU cores using a hashing function – either with support in the hardware which offloads the hashing for you, or in software. Click [here](https://forum.opnsense.org/index.php?topic=24409.0) to learn more about it.


1. System > Settings > Tunables
    1. Add `net.inet.rss.enabled` and set the value to `1`
    2. Add `net.inet.rss.bits` and set to `2`
    3. Add `net.isr.dispatch` and set to `hybrid`
    4. Add `net.isr.bindthreads` and set to `1`
    5. Add `net.isr.maxthreads` and set to `-1`
    6. Save
2. Reboot
3. Verify with `sudo netstat -Q`
    ```text
    Configuration:
    Setting                        Current        Limit
    Thread count                         8            8
    Default queue limit                256        10240
    Dispatch policy                 hybrid          n/a
    Threads bound to CPUs          enabled          n/a
    ```

## Syslog

Firewall logs are being sent to [Vector](https://github.com/vectordotdev/vector) which is running in my Kubernetes cluster. Vector is then shipping the logs to [Loki](https://github.com/grafana/loki) which is also running in my cluster.

1. System > Settings > Logging / targets
    - Add new logging target
      1. `Enabled` = `true`
      2. `Transport` = `UDP(4)`
      3. `Applications` = `filter (filterlog)`
      4. `Hostname` = `192.168.69.111` (Loki's Load Balancer IP)
      5. `Port` = `5140`
      6. `rfc5424` = `true`
      7. Save

## SMTP Relay

To ease the use of application configuration I have a SMTP Relay running on Opnsense using the Postfix plugin. From applications deployed in my Kubernetes cluster, to my nas, to my printer, all use the same configuration for SMTP without authentication.

1. System > Services > Postfix > General
    1. `SMTP Client Security` = `encrypt`
    2. `Smart Host` = `[smtp.fastmail.com]:465`
    3. `Enable SMTP Authentication` = `true`
    4. `Authentication Username` = `devin@<email-domain>`
    5. `Authentication Password` = `<app-password>`
    6. `Permit SASL Authenticated` = `false`
    7. Save
2. System > Services > Postfix > Domains
    - Add new domain
      1. `Domainname` = `<email-domain>`
      2. `Destination` = `[smtp.fastmail.com]:465`
      3. Save
    - Apply
3. System > Services > Postfix > Senders
    - Add new sender
      1. `Enabled` = `true`
      2. `Sender Address` = `admin@<email-domain>`
      3. Save
    - Apply
4. Verify
    ```sh
    swaks --server opnsense.turbo.ac --port 25 --to <email-address> --from <email-address>
    ```
