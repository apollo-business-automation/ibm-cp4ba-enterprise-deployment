#!/bin/bash

# Based on https://cloud.redhat.com/blog/getting-started-with-microsoft-sql-server-on-openshift

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
echo ">>>>$(print_timestamp) MSSQL install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Create Project"
oc new-project mssql

echo
echo ">>>>$(print_timestamp) Update Secret"
sed -f - secret.yaml > secret.target.yaml << SED_SCRIPT
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Create Secret"
oc apply -f secret.target.yaml

echo
echo ">>>>$(print_timestamp) Update PVC"
sed -f - pvc.yaml > pvc.target.yaml << SED_SCRIPT
s|{{STORAGE_CLASS_NAME}}|${STORAGE_CLASS_NAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Create pvc"
oc apply -f pvc.target.yaml

echo
echo ">>>>$(print_timestamp) Update Deployment"
sed -f - deployment.yaml > deployment.target.yaml << SED_SCRIPT
s|{{MSSQL_IMAGE_TAG}}|${MSSQL_IMAGE_TAG}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Create Deployment"
oc apply -f deployment.target.yaml

echo
echo ">>>>$(print_timestamp) Wait for mssql Deployment to be Available"
wait_for_k8s_resource_condition deployment/mssql Available

echo
echo ">>>>$(print_timestamp) Create Service"
oc apply -f service.yaml

echo
echo ">>>>$(print_timestamp) MSSQL install completed"
