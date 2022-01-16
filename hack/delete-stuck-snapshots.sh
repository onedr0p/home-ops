#!/usr/bin/env bash

volumesnapshotcontents=$(kubectl get --no-headers volumesnapshotcontents | awk '{print $1}')
for volumesnapshotcontent in $volumesnapshotcontents
do
    kubectl patch volumesnapshotcontents "${volumesnapshotcontent}" -p '{"metadata":{"finalizers":null}}' --type=merge
done

volumesnapshots=$(kubectl get --no-headers volumesnapshots -A | awk '{print $1","$2}')
for item in $volumesnapshots
do
    namespace="$(echo "${item}" | awk -F',' '{print $1}')"
    volumesnapshot="$(echo "${item}" | awk -F',' '{print $2}')"
    kubectl patch volumesnapshots "${volumesnapshot}" -n "${namespace}" -p '{"metadata":{"finalizers":null}}' --type=merge
done
