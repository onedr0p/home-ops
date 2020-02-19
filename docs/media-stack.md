# media-stack

> *Note*: this document is a work in progress

## Cluster addresses

- nzbget.default.svc.cluster.local
- jackett.default.svc.cluster.local
- nzbhydra2.default.svc.cluster.local
- qbittorrent-gui.default.svc.cluster.local
- sonarr.default.svc.cluster.local
- radarr.default.svc.cluster.local
- plex-kube-plex.default.svc.cluster.local


## Debugging connectivity

```bash
apt install -y dnsutils iputils-ping
nslookup nzbget.default.svc.cluster.local
ping nzbget.default.svc.cluster.local
```
