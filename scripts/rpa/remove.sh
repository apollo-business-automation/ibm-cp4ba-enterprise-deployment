#!/bin/bash

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) RPA remove started"

echo
echo ">>>>Source internal variables"
. ../internal-variables.sh

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Switch Project"
oc project ${CP4BA_PROJECT_NAME}

echo
echo ">>>>$(print_timestamp) Delete RPA instance"
oc delete RoboticProcessAutomation/rpa

echo
echo ">>>>$(print_timestamp) Wait for RPA instance deletion"
wait_for_k8s_resource_disappear RoboticProcessAutomation/rpa

echo
echo ">>>>$(print_timestamp) Wait for RPA UI Deployment deletion"
wait_for_k8s_resource_disappear deployment/rpa-ui-rpa

echo
echo ">>>>$(print_timestamp) Wait for RPA API Server Deployment deletion"
wait_for_k8s_resource_disappear deployment/rpa-apiserver-rpa

echo
echo ">>>>$(print_timestamp) Delete Secrets"
oc delete secret rpa-db
oc delete secret rpa-smtp
oc delete secret rpa-apiserver-rpa-dashboard

echo
echo ">>>>$(print_timestamp) Delete MSSQL DBs"
oc rsh -n mssql deployment/mssql << EOSSH
/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "${UNIVERSAL_PASSWORD}" -Q "drop database [automation]; drop database [knowledge]; drop database [wordnet]; drop database [address]; drop database [audit]"
EOSSH

echo
echo ">>>>$(print_timestamp) Delete RPA Subscription"
oc delete subscription rpa-subscription

echo
echo ">>>>$(print_timestamp) Wait for RPA Subscription deletion"
wait_for_k8s_resource_disappear Subscription/rpa-subscription

echo
echo ">>>>$(print_timestamp) Delete RPA CSVs and wait for deletion"
CSV=`oc get csv -o name | grep ibm-automation-rpa`
oc delete ${CSV}
wait_for_k8s_resource_disappear ${CSV}

CSV=`oc get csv -o name | grep ibm-mq`
oc delete ${CSV}
wait_for_k8s_resource_disappear ${CSV}

CSV=`oc get csv -o name | grep ibm-cloud-databases-redis.`
oc delete ${CSV}
wait_for_k8s_resource_disappear ${CSV}

echo
echo ">>>>$(print_timestamp) RPA remove completed"
