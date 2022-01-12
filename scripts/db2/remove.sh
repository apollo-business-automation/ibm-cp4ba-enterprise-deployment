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
echo ">>>>$(print_timestamp) DB2 remove started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Switch Project"
oc project db2

echo
echo ">>>>$(print_timestamp) Delete DB2uCluster instance"
oc delete DB2uCluster/db2ucluster

echo
echo ">>>>$(print_timestamp) Wait for DB2uCluster db2ucluster deletion"
wait_for_k8s_resource_disappear DB2uCluster/db2ucluster

echo
echo ">>>>$(print_timestamp) Delete project db2"
oc delete project db2

echo
echo ">>>>$(print_timestamp) Wait for project db2 deletion"
wait_for_k8s_resource_disappear project/db2

echo
echo ">>>>$(print_timestamp) DB2 remove completed"
