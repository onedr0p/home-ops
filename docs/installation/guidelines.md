# Guidelines

{% import 'links.jinja2' as links %}

Here are several suggestions I have prior to installing Kubernetes. Some of these suggestions may only apply to Ubuntu.

## Storage

- Do not use NFS for application configuration data if that application uses SQLite with write ahead logging (WAL), or uses file locks. Applications like Sonarr, Radarr, Lidarr are clear examples to avoid using NFS for the configuration volume.

## Networking

- Configure DNS on your nodes to use an upstream provider (e.g. `1.1.1.1`, `9.9.9.9`), or your router's IP if you have DNS configured there and it's not pointing to a local adblocker DNS.

- Do not use a Ad-blockers (PiHole, Adguard-Home, Blocky, etc.) DNS server for your k8s nodes. Ad-blockers should be used on devices with a web browser.

- Remove any search domains from your hosts `/etc/resolv.conf`. Search domains have an issue with alpine based containers and DNS might not resolve in them.

- Ensure you are using `iptables` in `nf_tables` mode.

- Enable packet forwarding on the hosts, and apply other sysctl tweaks:

```sh
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward=1
fs.inotify.max_user_watches=65536
EOF
sudo sysctl --system
```

- Make sure your nodes hostname appears in `/etc/hosts`, for example:

```sh
127.0.0.1 localhost
127.0.1.1 k8s-0
```

## System

- For a trade-off in speed over security, disable `AppArmor` and `Mitigations` on Ubuntu:

```sh
# /etc/default/grub
GRUB_CMDLINE_LINUX="apparmor=0 mitigations=off"
```

and then reconfigure grub and reboot:

```sh
sudo update-grub
sudo reboot
```

- Setup `unattended-upgrade` for use with {{ links.external('kured') }} to automatically patch and reboot your nodes.

- Disable swap
