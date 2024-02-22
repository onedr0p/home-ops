# Bootstrap

This is how I am bootstrapping Talos over PXE Boot using [Vyos](https://vyos.io/) and [Matchbox](https://matchbox.psdn.io/). Applications are then installed into the cluster with [Flux](https://fluxcd.io/).

## Vyos Config

### TFTP

> [!NOTE]
> My router IP address is `192.168.0.1`

```sh
set service tftp-server directory '/config/tftpboot'
set service tftp-server listen-address 192.168.0.1
curl -L -o /config/tftpboot/ipxe.efi http://boot.ipxe.org/ipxe.efi
curl -L -o /config/tftpboot/undionly.kpxe http://boot.ipxe.org/undionly.kpxe
sudo chown -R tftp:tftp /config/tftpboot/
```

### Matchbox

> [!NOTE]
> My container network is `192.168.254.0/24`. Configuration files under the **matchbox** dir need to go into the respected directories on Vyos.

```sh
mkdir -p /config/containers/matchbox/data/{assets,groups,profiles}
set container name matchbox arguments '-address=0.0.0.0:80 -log-level=debug'
set container name matchbox cap-add 'net-bind-service'
set container name matchbox image 'quay.io/poseidon/matchbox:v0.10.0'
set container name matchbox memory '0'
set container name matchbox network containers address '192.168.254.12'
set container name matchbox shared-memory '0'
set container name matchbox volume matchbox-data destination '/var/lib/matchbox'
set container name matchbox volume matchbox-data mode 'rw'
set container name matchbox volume matchbox-data propagation 'private'
set container name matchbox volume matchbox-data source '/config/containers/matchbox/data'
curl -L -o /config/containers/matchbox/data/assets/vmlinuz https://factory.talos.dev/image/d715f723f882b1e1e8063f1b89f237dcc0e3bd000f9f970243af59c8baae0100/v1.6.4/kernel-amd64
curl -L -o /config/containers/matchbox/data/assets/initramfs.xz https://factory.talos.dev/image/d715f723f882b1e1e8063f1b89f237dcc0e3bd000f9f970243af59c8baae0100/v1.6.4/initramfs-amd64.xz
```

### DHCP

> [!NOTE]
> My node network is `192.168.42.0/24`

```sh
set service dhcp-server global-parameters 'option system-arch code 93 = unsigned integer 16;'
set service dhcp-server shared-network-name SERVERS subnet 192.168.42.0/24 subnet-parameters 'allow bootp;'
set service dhcp-server shared-network-name SERVERS subnet 192.168.42.0/24 subnet-parameters 'allow booting;'
set service dhcp-server shared-network-name SERVERS subnet 192.168.42.0/24 subnet-parameters 'next-server 192.168.0.1;'
set service dhcp-server shared-network-name SERVERS subnet 192.168.42.0/24 subnet-parameters 'if exists user-class and option user-class = &quot;iPXE&quot; {'
set service dhcp-server shared-network-name SERVERS subnet 192.168.42.0/24 subnet-parameters 'filename &quot;http://192.168.254.12/boot.ipxe&quot;;'
set service dhcp-server shared-network-name SERVERS subnet 192.168.42.0/24 subnet-parameters '} else {'
set service dhcp-server shared-network-name SERVERS subnet 192.168.42.0/24 subnet-parameters 'filename &quot;ipxe.efi&quot;;'
set service dhcp-server shared-network-name SERVERS subnet 192.168.42.0/24 subnet-parameters '}'
```

## Bootstrap

```sh
task bootstrap:main
```
