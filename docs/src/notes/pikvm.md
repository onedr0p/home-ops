# PiKVM

## Update PiKVM

```sh
rw; pacman -Syyu
reboot
```

## Load TESmart KVM

1. Add or replace the file `/etc/kvmd/override.yaml`
    ```yaml
    kvmd:
        prometheus:
            auth:
                enabled: false
        gpio:
            drivers:
                tes:
                    type: tesmart
                    host: 192.168.1.10
                    port: 5000
            scheme:
                server0_led:
                    driver: tes
                    pin: 0
                    mode: input
                server0_switch:
                    driver: tes
                    pin: 0
                    mode: output
                    switch: false
                server1_led:
                    driver: tes
                    pin: 1
                    mode: input
                server1_switch:
                    driver: tes
                    pin: 1
                    mode: output
                    switch: false
                server2_led:
                    driver: tes
                    pin: 2
                    mode: input
                server2_switch:
                    driver: tes
                    pin: 2
                    mode: output
                    switch: false
                server3_led:
                    driver: tes
                    pin: 3
                    mode: input
                server3_switch:
                    driver: tes
                    pin: 3
                    mode: output
                    switch: false
                server4_led:
                    driver: tes
                    pin: 4
                    mode: input
                server4_switch:
                    driver: tes
                    pin: 4
                    mode: output
                    switch: false
                server5_led:
                    driver: tes
                    pin: 5
                    mode: input
                server5_switch:
                    driver: tes
                    pin: 5
                    mode: output
                    switch: false
                server6_led:
                    driver: tes
                    pin: 6
                    mode: input
                server6_switch:
                    driver: tes
                    pin: 6
                    mode: output
                    switch: false
                server7_led:
                    driver: tes
                    pin: 7
                    mode: input
                server7_switch:
                    driver: tes
                    pin: 7
                    mode: output
                    switch: false
            view:
                table:
                    - ["TESMART Switch"]
                    - []
                    - ["#device-0", server0_led, server0_switch|Switch]
                    - ["#device-1", server1_led, server1_switch|Switch]
                    - ["#device-2", server2_led, server2_switch|Switch]
                    - ["#device-3", server3_led, server3_switch|Switch]
                    - ["#device-4", server4_led, server4_switch|Switch]
                    - ["#device-5", server5_led, server5_switch|Switch]
                    - ["#device-6", server6_led, server6_switch|Switch]
                    - ["#device-7", server7_led, server7_switch|Switch]
    ```

2. Restart kvmd
    ```sh
    systemctl restart kvmd.service
    ```

## Load Custom EDID

1. Add or replace the file `/etc/kvmd/tc358743-edid.hex`
    ```text
    00FFFFFFFFFFFF0052628888008888881C150103800000780AEE91A3544C99260F505425400001000100010001000100010001010101D32C80A070381A403020350040442100001E7E1D00A0500019403020370080001000001E000000FC0050492D4B564D20566964656F0A000000FD00323D0F2E0F000000000000000001C402030400DE0D20A03058122030203400F0B400000018E01500A04000163030203400000000000018B41400A050D011203020350080D810000018AB22A0A050841A3030203600B00E1100001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000045
    ```

2. Restart kvmd
    ```sh
    systemctl restart kvmd.service
    ```

## Disable SSL

1. Add or replace the file `/etc/kvmd/nginx/nginx.conf`
    ```nginx
    worker_processes 4;

    error_log stderr;

    include /usr/share/kvmd/extras/*/nginx.ctx-main.conf;

    events {
        worker_connections 1024;
        use epoll;
        multi_accept on;
    }

    http {
        types_hash_max_size 4096;
        server_names_hash_bucket_size 128;

        access_log off;

        include /etc/kvmd/nginx/mime-types.conf;
        default_type application/octet-stream;
        charset utf-8;

        sendfile on;
        tcp_nodelay on;
        tcp_nopush on;
        keepalive_timeout 10;
        client_max_body_size 4k;

        client_body_temp_path    /tmp/kvmd-nginx/client_body_temp;
        fastcgi_temp_path        /tmp/kvmd-nginx/fastcgi_temp;
        proxy_temp_path            /tmp/kvmd-nginx/proxy_temp;
        scgi_temp_path            /tmp/kvmd-nginx/scgi_temp;
        uwsgi_temp_path            /tmp/kvmd-nginx/uwsgi_temp;

        include /etc/kvmd/nginx/kvmd.ctx-http.conf;
        include /usr/share/kvmd/extras/*/nginx.ctx-http.conf;

        server {
            listen 80;
            listen [::]:80;
            server_name localhost;
            include /etc/kvmd/nginx/kvmd.ctx-server.conf;
            include /usr/share/kvmd/extras/*/nginx.ctx-server.conf;
        }
    }
    ```

2. Restart kvmd-nginx
    ```sh
    systemctl restart kvmd-nginx.service
    ```

## Monitoring

### Disable auth on prometheus exporter

```sh
rw
nano /usr/lib/python3.11/site-packages/kvmd/apps/kvmd/api/export.py
# Add the False arg on the exposed_http decorator...
# @exposed_http("GET", "/export/prometheus/metrics", False)
ro
systemctl restart kvmd.service
```

### Install node-exporter

```sh
pacman -S prometheus-node-exporter
systemctl enable --now prometheus-node-exporter
```

### Install promtail

1. Install promtail
    ```sh
    pacman -S promtail
    systemctl enable promtail
    ```

2. Override the promtail systemd service
    ```sh
    mkdir -p /etc/systemd/system/promtail.service.d/
    cat >/etc/systemd/system/promtail.service.d/override.conf <<EOL
    [Service]
    Type=simple
    ExecStart=
    ExecStart=/usr/bin/promtail -config.file /etc/loki/promtail.yaml
    EOL
    ```

3. Add or replace the file `/etc/loki/promtail.yaml`
    ```yaml
    server:
      log_level: info
      disable: true

    client:
      url: "https://loki.devbu.io/loki/api/v1/push"

    positions:
      filename: /tmp/positions.yaml

    scrape_configs:
      - job_name: journal
        journal:
          path: /run/log/journal
          max_age: 12h
          labels:
            job: systemd-journal
        relabel_configs:
          - source_labels: ["__journal__systemd_unit"]
            target_label: unit
          - source_labels: ["__journal__hostname"]
            target_label: hostname
    ```

4. Start promtail
    ```sh
    systemctl daemon-reload
    systemctl start promtail.service
    ```
