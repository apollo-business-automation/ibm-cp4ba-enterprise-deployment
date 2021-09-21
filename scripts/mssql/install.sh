#!/bin/bash

# Based on https://cloud.redhat.com/blog/getting-started-with-microsoft-sql-server-on-openshift

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) MSSQL install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Create Project"
oc new-project mssql

echo
echo ">>>>$(print_timestamp) Create Secret"
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" secret.yaml
oc apply -f secret.yaml

echo
echo ">>>>$(print_timestamp) Update PVC"
sed -i "s|{{STORAGE_CLASS_NAME}}|${STORAGE_CLASS_NAME}|g" pvc.yaml

echo
echo ">>>>$(print_timestamp) Create pvc"
oc apply -f pvc.yaml

echo
echo ">>>>$(print_timestamp) Create Deployment"
oc apply -f deployment.yaml

echo
echo ">>>>$(print_timestamp) Wait for mssql Deployment to be Available"
wait_for_k8s_resource_condition deployment/mssql Available

echo
echo ">>>>$(print_timestamp) Create Service"
oc apply -f service.yaml

echo
echo ">>>>$(print_timestamp) MSSQL install completed"
