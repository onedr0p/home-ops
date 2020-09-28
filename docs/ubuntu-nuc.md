# ubuntu-nuc

## Bios Settings

> F2: Bios
>
> F7: Update Bios

## Adjust BIOS

- F9 (Set defaults)
- Use settings in [these photos](https://photos.app.goo.gl/r5pk2wqpugLCyQxM8)

## Update BIOS no monitor

Insert USB, Power on, Spam F7, 5 sec, Enter, Down arrow, Enter, Enter

## Install Ubuntu 20.04

### Verify date

```bash
timedatectl
```

### Set DNS server with DHCP

```yaml
# This is the network config written by 'subiquity'
network:
  ethernets:
    eno1:
      dhcp4: true
      dhcp4-overrides:
        use-dns: false
      nameservers:
        addresses: [192.168.42.1]
  version: 2
```

## Access local dns

```bash
nslookup ...
```
