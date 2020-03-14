# Uninstall

```bash
helm uninstall stash --namespace kube-system
```

## Delete all resources

```bash
kubectl delete restics.stash.appscode.com --all;
kubectl delete recoveries.stash.appscode.com --all;
kubectl delete backupconfigurations.stash.appscode.com --all;
kubectl delete backupbatches.stash.appscode.com --all;
kubectl delete backupsessions.stash.appscode.com --all;
kubectl delete restoresessions.stash.appscode.com --all;
kubectl delete backupblueprints.stash.appscode.com --all;
kubectl delete tasks.stash.appscode.com --all;
kubectl delete functions.stash.appscode.com --all;
kubectl delete appbindings.appcatalog.appscode.com --all;
kubectl delete repositories.stash.appscode.com --all;
```

## Delete CRDs

```bash
kubectl delete crd/restics.stash.appscode.com;
kubectl delete crd/recoveries.stash.appscode.com;
kubectl delete crd/backupconfigurations.stash.appscode.com;
kubectl delete crd/backupbatches.stash.appscode.com;
kubectl delete crd/backupsessions.stash.appscode.com;
kubectl delete crd/restoresessions.stash.appscode.com;
kubectl delete crd/backupblueprints.stash.appscode.com;
kubectl delete crd/tasks.stash.appscode.com;
kubectl delete crd/functions.stash.appscode.com;
kubectl delete crd/appbindings.appcatalog.appscode.com;
kubectl delete crd/repositories.stash.appscode.com;
```

## Delete API Services

```bash
kubectl delete apiservice/v1beta1.admission.stash.appscode.com;
kubectl delete apiservice/v1alpha1.admission.stash.appscode.com;
kubectl delete apiservice/v1alpha1.repositories.stash.appscode.com;
```

## Delete PodSecurityPolicy

```bash
kubectl delete PodSecurityPolicy/stash-backup-job
kubectl delete PodSecurityPolicy/stash-backupsession-cron
kubectl delete PodSecurityPolicy/stash
kubectl delete PodSecurityPolicy/stash-restore-job
```

## Delete ClusterRole and ClusterRoleBinding and RoleBinding

```bash
kubectl delete ClusterRole/stash
kubectl delete ClusterRole/appscode:stash:edit
kubectl delete ClusterRole/appscode:stash:view
kubectl delete ClusterRoleBinding/stash-apiserver-auth-delegator
kubectl delete ClusterRoleBinding/stash
kubectl delete RoleBinding/stash-apiserver-extension-server-authentication-reader -n kube-system
```
