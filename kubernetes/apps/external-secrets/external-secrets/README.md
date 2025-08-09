# external-secrets

## NAS Deployments

### onepassword-connect

```yaml
services:
  onepassword-api:
    container_name: onepassword-api
    environment:
      OP_HTTP_PORT: 7070
      OP_SESSION: aHVudGVyMgo=
      XDG_DATA_HOME: /config
    image: ghcr.io/1password/connect-api:1.7.4
    network_mode: host
    restart: unless-stopped
    volumes:
      - data:/config
  onepassword-sync:
    container_name: onepassword-sync
    environment:
      OP_HTTP_PORT: 7071
      OP_SESSION: aHVudGVyMgo=
      XDG_DATA_HOME: /config
    image: ghcr.io/1password/connect-sync:1.7.4
    network_mode: host
    restart: unless-stopped
    volumes:
      - data:/config
volumes:
  data:
    driver: local
    driver_opts:
      device: tmpfs
      o: uid=999,gid=999
      type: tmpfs
```
