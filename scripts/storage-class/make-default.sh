#!/bin/bash

echo
echo ">>>>Source internal variables"
. ../internal-variables.sh

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) Make Storage Class default install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Set Storage Class as default  "
# Based on https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/
oc get storageclass -o name | xargs oc patch -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
oc patch storageclass ${STORAGE_CLASS_NAME} -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

echo
echo ">>>>$(print_timestamp) Make Storage Class default install completed"
