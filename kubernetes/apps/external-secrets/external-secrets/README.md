# Onepassword Connect

## Deployment

```yaml
services:
  onepassword-api:
    container_name: onepassword-api
    environment:
      OP_BUS_PEERS: localhost:11221
      OP_BUS_PORT: 11220
      OP_HTTP_PORT: 7070
      OP_SESSION: aHVudGVyMgo=
      XDG_DATA_HOME: /config
    image: docker.io/1password/connect-api:1.7.3
    network_mode: host
    restart: unless-stopped
    volumes:
      - data:/config
  onepassword-sync:
    container_name: onepassword-sync
    environment:
      OP_BUS_PEERS: localhost:11221
      OP_BUS_PORT: 11220
      OP_HTTP_PORT: 7071
      OP_SESSION: aHVudGVyMgo=
      XDG_DATA_HOME: /config
    image: docker.io/1password/connect-sync:1.7.3
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
