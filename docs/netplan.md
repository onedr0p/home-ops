# Netplan info

> *Note*: this document is a work in progress

## Bond ye ether ports

```yaml
network:
  version: 2
  ethernets:
    eports:
      match:
        name: enp*
      optional: true
  bonds:
    bond0:
      interfaces: [eports]
      addresses: [ 192.168.42.30/24 ]
      gateway4: 192.168.42.1
      nameservers:
        search: [ lan, unifi.lan ]
        addresses:
            - "192.168.1.15"
      parameters:
        mode: 802.3ad
        lacp-rate: fast
        mii-monitor-interval: 100
```

## Set ye ether ports to MTU 9000

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens160:
      match:
        macaddress: 00:0c:29:0d:43:06
      mtu: 9000
      addresses: [ 192.168.42.46/24 ]
      gateway4: 192.168.42.1
      nameservers:
          search: [ lan ]
          addresses:
              - "192.168.1.15"
```
