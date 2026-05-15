machine:
  kubelet:
    defaultRuntimeSeccompProfileEnabled: true
    disableManifestsDirectory: true
    extraConfig:
      serializeImagePulls: false
    image: ghcr.io/siderolabs/kubelet:v{{ .KubernetesVersion }}
    nodeIP:
      validSubnets:
        - 192.168.42.0/24
