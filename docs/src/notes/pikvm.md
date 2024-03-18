# PiKVM

## Update PiKVM

```sh
rw; pacman -Syyu
reboot
```

## Load TESmart KVM

1. Add or replace the file `/etc/kvmd/override.yaml`
    ```yaml
    ---

    nginx:
      https:
        enabled: false

    kvmd:
      auth:
        enabled: false
      prometheus:
        auth:
          enabled: false
      streamer:
        desired_fps:
          default: 20
        h264_bitrate:
          default: 2500
        h264_gop:
          default: 30
        quality: 75
      gpio:
        drivers:
          tes:
            type: tesmart
            host: 192.168.1.10
            port: 5000
          wol_dev0:
            type: wol
            mac: 1c:69:7a:0d:8d:99
          wol_dev1:
            type: wol
            mac: 1c:69:7a:0e:f7:ed
          wol_dev2:
            type: wol
            mac: 1c:69:7a:0d:62:d4
          wol_dev3:
            type: wol
            mac: 94:c6:91:a7:7b:2b
          wol_dev4:
            type: wol
            mac: 94:c6:91:af:15:3d
          wol_dev5:
            type: wol
            mac: 1c:69:7a:09:bf:39
          reboot:
            type: cmd
            cmd: ["/usr/bin/sudo", "reboot"]
          restart_service:
            type: cmd
            cmd: ["/usr/bin/sudo", "systemctl", "restart", "kvmd"]
        scheme:
          dev0_led:
            driver: tes
            pin: 0
            mode: input
          dev0_btn:
            driver: tes
            pin: 0
            mode: output
            switch: false
          dev0_wol:
            driver: wol_dev0
            pin: 0
            mode: output
            switch: false
          dev1_led:
            driver: tes
            pin: 1
            mode: input
          dev1_btn:
            driver: tes
            pin: 1
            mode: output
            switch: false
          dev1_wol:
            driver: wol_dev1
            pin: 0
            mode: output
            switch: false
          dev2_led:
            driver: tes
            pin: 2
            mode: input
          dev2_btn:
            driver: tes
            pin: 2
            mode: output
            switch: false
          dev2_wol:
            driver: wol_dev2
            pin: 0
            mode: output
            switch: false
          dev3_led:
            driver: tes
            pin: 3
            mode: input
          dev3_btn:
            driver: tes
            pin: 3
            mode: output
            switch: false
          dev3_wol:
            driver: wol_dev3
            pin: 0
            mode: output
            switch: false
          dev4_led:
            driver: tes
            pin: 4
            mode: input
          dev4_btn:
            driver: tes
            pin: 4
            mode: output
            switch: false
          dev4_wol:
            driver: wol_dev4
            pin: 0
            mode: output
            switch: false
          dev5_led:
            driver: tes
            pin: 5
            mode: input
          dev5_btn:
            driver: tes
            pin: 5
            mode: output
            switch: false
          dev5_wol:
            driver: wol_dev5
            pin: 0
            mode: output
            switch: false
          dev6_led:
            driver: tes
            pin: 6
            mode: input
          dev6_btn:
            driver: tes
            pin: 6
            mode: output
            switch: false
          dev7_led:
            driver: tes
            pin: 7
            mode: input
          dev7_btn:
            driver: tes
            pin: 7
            mode: output
            switch: false
          reboot_button:
            driver: reboot
            pin: 0
            mode: output
            switch: false
          restart_service_button:
            driver: restart_service
            pin: 0
            mode: output
            switch: false
        view:
          header:
            title: Devices
          table:
            - ["#pikvm", "pikvm_led|green", "restart_service_button|confirm|Service", "reboot_button|confirm|Reboot"]
            - ["#0", "dev0_led", "dev0_btn | KVM", "dev0_wol | WOL"]
            - ["#1", "dev1_led", "dev1_btn | KVM", "dev1_wol | WOL"]
            - ["#2", "dev2_led", "dev2_btn | KVM", "dev2_wol | WOL"]
            - ["#3", "dev3_led", "dev3_btn | KVM", "dev3_wol | WOL"]
            - ["#4", "dev4_led", "dev4_btn | KVM", "dev4_wol | WOL"]
            - ["#5", "dev5_led", "dev5_btn | KVM", "dev5_wol | WOL"]
            - ["#6", "dev6_led", "dev6_btn"]
            - ["#7", "dev7_led", "dev7_btn"]
    ```

2. Restart kvmd
    ```sh
    systemctl restart kvmd.service
    ```

## Monitoring

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
