#!/bin/bash

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) PM remove started"

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
echo ">>>>$(print_timestamp) Delete PM instance"
oc delete ProcessMining/processmining

echo
echo ">>>>$(print_timestamp) Wait for ProcessMining processmining deletion"
wait_for_k8s_resource_disappear ProcessMining/processmining

echo
echo ">>>>$(print_timestamp) Delete PM DBs Secret"
oc delete secret pm-dbs

echo
echo ">>>>$(print_timestamp) Delete PM Secret"
oc delete secret pm-tls-secret

echo
echo ">>>>$(print_timestamp) Delete PM Subscription"
oc delete subscription processmining-subscription

echo
echo ">>>>$(print_timestamp) Wait for PM Subscription deletion"
wait_for_k8s_resource_disappear Subscription/processmining-subscription

echo
echo ">>>>$(print_timestamp) Delete PM CSV"
CSV=`oc get csv -o name | grep processmining`
oc delete ${CSV}

echo
echo ">>>>$(print_timestamp) Wait for PM CSV deletion"
wait_for_k8s_resource_disappear ${CSV}

echo
echo ">>>>$(print_timestamp) Delete Tablespaces and Schema"
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 connect to CP4BA
db2 DROP TABLESPACE PM_TS;
db2 DROP TABLESPACE PM_TEMP_TS;
db2 DROP TABLESPACE PM_SYSTMP_TS;
db2 "CALL SYSPROC.ADMIN_DROP_SCHEMA('PM', NULL, 'ERRORSCHEMA', 'ERRORTABLE')"
EOSSH

echo
echo ">>>>$(print_timestamp) Delete DB users"
# Based on https://www.ibm.com/docs/en/db2/11.5?topic=ldap-managing-users
ldap_pod=$(oc get pod -n db2 -o name | grep ldap)
echo
echo ">>>>$(print_timestamp) Delete DB user pm"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/removeLdapUser.py -u pm

echo
echo ">>>>$(print_timestamp) Delete Mongo DB"
oc rsh -n mongodb-pm deployment/mongodb-pm << EOSSH
mongo --username root --password ${UNIVERSAL_PASSWORD} --authenticationDatabase admin <<EOF
use processmining
db.dropUser("root")
db.dropDatabase()
EOF
EOSSH

echo
echo ">>>>$(print_timestamp) PM remove completed"
