---
cluster:
  network:
    cni:
      name: none
    dnsDomain: cluster.local
    podSubnets:
      - 10.42.0.0/16
    serviceSubnets:
      - 10.43.0.0/16
  discovery:
    enabled: true
    registries:
      kubernetes:
        disabled: true
      service:
        disabled: false
machine:
  install:
    diskSelector:
      model: MK000480GWCEV
    image: factory.talos.dev/metal-installer/{{ .SchematicID }}:v1.13.2
    wipe: false
  kubelet:
    defaultRuntimeSeccompProfileEnabled: true
    disableManifestsDirectory: true
    extraConfig:
      serializeImagePulls: false
    image: ghcr.io/siderolabs/kubelet:v1.36.1
    nodeIP:
      validSubnets:
        - 192.168.42.0/24
  features:
    apidCheckExtKeyUsage: true
    diskQuotaSupport: true
    hostDNS:
      enabled: true
      forwardKubeDNSToHost: true
      resolveMemberNames: true
    kubePrism:
      enabled: true
      port: 7445
    rbac: true
  files:
    - op: create
      path: /etc/cri/conf.d/20-customization.part
      content: |
        [plugins."io.containerd.cri.v1.images"]
          discard_unpacked_layers = false
        [plugins."io.containerd.cri.v1.runtime"]
          device_ownership_from_security_context = true
    - op: overwrite
      path: /etc/nfsmount.conf
      permissions: 0o644
      content: |
        [ NFSMount_Global_Options ]
        nfsvers=4.2
        hard=True
        nconnect=8
        noatime=True
        rsize=1048576
        wsize=1048576
  kernel:
    modules:
      - name: nbd
      - name: thunderbolt
  nodeLabels:
    node.kubernetes.io/gpu: "true"
    topology.kubernetes.io/region: main
  sysctls:
    fs.inotify.max_user_instances: "8192"
    fs.inotify.max_user_watches: "1048576"
    net.core.default_qdisc: fq
    net.core.rmem_max: "67108864"
    net.core.wmem_max: "67108864"
    net.ipv4.neigh.default.gc_thresh1: "4096"
    net.ipv4.neigh.default.gc_thresh2: "8192"
    net.ipv4.neigh.default.gc_thresh3: "16384"
    net.ipv4.ping_group_range: 0 2147483647
    net.ipv4.tcp_congestion_control: bbr
    net.ipv4.tcp_fastopen: "3"
    net.ipv4.tcp_mtu_probing: "1"
    net.ipv4.tcp_notsent_lowat: "131072"
    net.ipv4.tcp_rmem: 4096 87380 33554432
    net.ipv4.tcp_slow_start_after_idle: "0"
    net.ipv4.tcp_window_scaling: "1"
    net.ipv4.tcp_wmem: 4096 65536 33554432
    sunrpc.tcp_max_slot_table_entries: "128"
    sunrpc.tcp_slot_table_entries: "128"
    user.max_user_namespaces: "11255"
    vm.nr_hugepages: "1024"
---
apiVersion: v1alpha1
kind: HostnameConfig
hostname: "{{ .Node.Host }}"
auto: "off"
---
apiVersion: v1alpha1
kind: LinkAliasConfig
name: net0
selector:
  match: link.driver == "atlantic" && mac(link.permanent_addr).startsWith("00:30:93:12:")
---
apiVersion: v1alpha1
kind: BondConfig
name: bond0
links:
  - net0
bondMode: active-backup
mtu: 9000
---
apiVersion: v1alpha1
kind: DHCPv4Config
name: bond0
clientIdentifier: mac
---
apiVersion: v1alpha1
kind: VLANConfig
name: bond0.70
vlanID: 70
parent: bond0
mtu: 9000
---
apiVersion: v1alpha1
kind: VLANConfig
name: bond0.90
vlanID: 90
parent: bond0
mtu: 9000
---
apiVersion: v1alpha1
kind: UserVolumeConfig
name: local-hostpath
provisioning:
  diskSelector:
    match: disk.model == "Corsair MP600 MICRO" && !system_disk
  minSize: 1TB
---
apiVersion: v1alpha1
kind: WatchdogTimerConfig
device: /dev/watchdog0
timeout: 5m
