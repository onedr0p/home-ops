cluster:
  apiServer:
    auditPolicy:
      apiVersion: audit.k8s.io/v1
      kind: Policy
      rules:
        - level: Metadata
    certSANs:
      - k8s.internal
    disablePodSecurityPolicy: true
    admissionControl:
      - name: PodSecurity
        $patch: delete
    extraArgs:
      enable-aggregator-routing: "true"
      feature-gates: HPAScaleToZero=true
    image: registry.k8s.io/kube-apiserver:v{{ .KubernetesVersion }}
  controllerManager:
    extraArgs:
      bind-address: 0.0.0.0
      feature-gates: HPAScaleToZero=true
    image: registry.k8s.io/kube-controller-manager:v{{ .KubernetesVersion }}
  proxy:
    disabled: true
    image: registry.k8s.io/kube-proxy:v{{ .KubernetesVersion }}
  scheduler:
    config:
      apiVersion: kubescheduler.config.k8s.io/v1
      kind: KubeSchedulerConfiguration
      profiles:
        - schedulerName: default-scheduler
          plugins:
            score:
              disabled:
                - name: ImageLocality
          pluginConfig:
            - name: PodTopologySpread
              args:
                defaultingType: List
                defaultConstraints:
                  - maxSkew: 1
                    topologyKey: kubernetes.io/hostname
                    whenUnsatisfiable: ScheduleAnyway
    extraArgs:
      bind-address: 0.0.0.0
    image: registry.k8s.io/kube-scheduler:v{{ .KubernetesVersion }}
