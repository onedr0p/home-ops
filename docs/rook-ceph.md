# rook-ceph

https://rook.io/docs/rook/v1.2/ceph-common-issues.html

## Toolbox

```bash
kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash
```

## Crashes

Sometime ceph will report a `HEALTH_WARN` even when the health is fine, in order to get ceph to report back healthly do the following...

```bash
ceph crash ls
# if you want to read the message
ceph crash info <id>
# archive crash report
ceph crash archive <id>
# or, archive all crash reports
ceph crash archive-all
```
