#!/bin/bash

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) RPA remove started"

echo
echo ">>>>Source internal variables"
. ../inernal-variables.sh

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Switch Project"
oc project ${PROJECT_NAME}

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
echo ">>>>$(print_timestamp) Delete IAM Teams"
# Based on https://www.ibm.com/docs/en/cpfs?topic=apis-team-management#delete

# Get access token for administrative user
ACCESS_TOKEN=`curl -k -X POST -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" \
-d "grant_type=password&username=cpfsadmin&password=${UNIVERSAL_PASSWORD}&scope=openid" \
https://cp-console.${OCP_APPS_ENDPOINT}/idprovider/v1/auth/identitytoken \
| jq -r '.access_token'`

# Delete rpa-users team
curl -k -X DELETE --header "Authorization: Bearer $ACCESS_TOKEN" \
"https://cp-console.${OCP_APPS_ENDPOINT}/idmgmt/identity/api/v1/teams/rpa-users"

# Delete rpa-admins team
curl -k -X DELETE --header "Authorization: Bearer $ACCESS_TOKEN" \
"https://cp-console.${OCP_APPS_ENDPOINT}/idmgmt/identity/api/v1/teams/rpa-admins"

# Delete rpa-superadmins team
curl -k -X DELETE --header "Authorization: Bearer $ACCESS_TOKEN" \
"https://cp-console.${OCP_APPS_ENDPOINT}/idmgmt/identity/api/v1/teams/rpa-superadmins"

echo
echo ">>>>$(print_timestamp) Delete MSSQL DBs"
oc rsh -n mssql deployment/mssql << EOSSH
/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "${UNIVERSAL_PASSWORD}" -Q "drop database [automation]; drop database [knowledge]; drop database [wordnet]; drop database [address]"
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
