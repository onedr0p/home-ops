#!/usr/bin/env bash

# kubectl delete volumesnapshots.snapshot.storage.k8s.io --all
volumesnapshots=$(kubectl get --no-headers volumesnapshots -A | awk '{print $1","$2}')
for item in $volumesnapshots
do
    namespace="$(echo "${item}" | awk -F',' '{print $1}')"
    volumesnapshot="$(echo "${item}" | awk -F',' '{print $2}')"
    kubectl patch volumesnapshots "${volumesnapshot}" -n "${namespace}" -p '{"metadata":{"finalizers":null}}' --type=merge
done

# kubectl delete volumesnapshotcontents.snapshot.storage.k8s.io --all
volumesnapshotcontents=$(kubectl get --no-headers volumesnapshotcontents | awk '{print $1}')
for volumesnapshotcontent in $volumesnapshotcontents
do
    kubectl patch volumesnapshotcontents "${volumesnapshotcontent}" -p '{"metadata":{"finalizers":null}}' --type=merge
done
