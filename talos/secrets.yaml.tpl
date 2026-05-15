cluster:
  id: op://kubernetes/talos/CLUSTER_ID
  secret: op://kubernetes/talos/CLUSTER_SECRET
secrets:
  bootstraptoken: op://kubernetes/talos/CLUSTER_TOKEN
  secretboxencryptionsecret: op://kubernetes/talos/CLUSTER_SECRETBOXENCRYPTIONSECRET
trustdinfo:
  token: op://kubernetes/talos/MACHINE_TOKEN
certs:
  etcd:
    crt: op://kubernetes/talos/CLUSTER_ETCD_CA_CRT
    key: op://kubernetes/talos/CLUSTER_ETCD_CA_KEY
  k8s:
    crt: op://kubernetes/talos/CLUSTER_CA_CRT
    key: op://kubernetes/talos/CLUSTER_CA_KEY
  k8saggregator:
    crt: op://kubernetes/talos/CLUSTER_AGGREGATORCA_CRT
    key: op://kubernetes/talos/CLUSTER_AGGREGATORCA_KEY
  k8sserviceaccount:
    key: op://kubernetes/talos/CLUSTER_SERVICEACCOUNT_KEY
  os:
    crt: op://kubernetes/talos/MACHINE_CA_CRT
    key: op://kubernetes/talos/MACHINE_CA_KEY
