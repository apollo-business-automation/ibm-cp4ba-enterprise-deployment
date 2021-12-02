#!/bin/bash

# Based on https://www.ibm.com/docs/en/db2-data-mgr-console/3.1.x?topic=configuring-setting-up-db2-data-management-console

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
echo ">>>>$(print_timestamp) DB2MC install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Create Project"
oc new-project db2mc

echo
echo ">>>>$(print_timestamp) Add anyuid SCC to default SA"
oc adm policy add-scc-to-user anyuid system:serviceaccount:db2mc:default

echo
echo ">>>>$(print_timestamp) Create wildcard certificate Secret"
oc create secret generic wildcard --from-file=cert.pem=../global-ca/wildcard.crt --from-file=key.pem=../global-ca/wildcard.key

echo
echo ">>>>$(print_timestamp) Update PVC"
yq w -i pvc.yaml spec.storageClassName "${STORAGE_CLASS_NAME}"

echo
echo ">>>>$(print_timestamp) Create PVC"
oc apply -f pvc.yaml

echo
echo ">>>>$(print_timestamp) Deploy Deployment"
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" deployment.yaml
oc apply -f deployment.yaml

echo
echo ">>>>$(print_timestamp) Wait for Deployment to be Available"
wait_for_k8s_resource_condition deployment/db2mc Available

echo
echo ">>>>$(print_timestamp) Create Service"
oc apply -f service.yaml

echo
echo ">>>>$(print_timestamp) Create Route"
oc create route passthrough db2mc --hostname=db2mc.${OCP_APPS_ENDPOINT} \
--service=db2mc --insecure-policy=Redirect

echo
echo ">>>>$(print_timestamp) Wait for Route to be Admitted"
wait_for_k8s_resource_condition_generic route/db2mc ".status.ingress[0].conditions[0].status" True
sleep 5

echo
echo ">>>>$(print_timestamp) Create DB2MC DB"
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 CREATE DATABASE DB2MC AUTOMATIC STORAGE YES PAGESIZE 32 K;
db2 activate db DB2MC
EOSSH

echo
echo ">>>>$(print_timestamp) Get auth token"
AUTH_TOKEN=`curl -k -X POST \
https://db2mc.${OCP_APPS_ENDPOINT}/dbapi/v4/auth/tokens \
-H 'content-type: application/json' \
-d '{"userid":"cpadmin","password":"'${UNIVERSAL_PASSWORD}'"}' | jq -r '.token'`

echo
echo ">>>>$(print_timestamp) Setup repository"
curl -k -X POST \
https://db2mc.${OCP_APPS_ENDPOINT}/dbapi/v4/repository \
-H "authorization: Bearer ${AUTH_TOKEN}" \
-H 'content-type: application/json' \
-d '{"host":"'${DB2_HOSTNAME}'","dataServerType":"DB2LUW","databaseName":"DB2MC",
"port":"50000","collectionCred":{"user":"db2inst1","password":"'${UNIVERSAL_PASSWORD}'"},"sslConnection":"false"}'

echo
echo ">>>>$(print_timestamp) Add connection to repository DB"
add_db2mc_connection DB2MC

echo
echo ">>>>$(print_timestamp) DB2MC install completed"
