#!/bin/bash

echo
echo ">>>>Source internal variables"
. ../inernal-variables.sh

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) MSSQL remove started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Delete project gitea"
oc delete project mssql

echo
echo ">>>>$(print_timestamp) Wait for Project mssql deletion"
wait_for_k8s_resource_disappear project/mssql

echo
echo ">>>>$(print_timestamp) MSSQL remove completed"
