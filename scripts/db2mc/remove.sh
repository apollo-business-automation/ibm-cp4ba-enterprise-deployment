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
echo ">>>>$(print_timestamp) DB2MC remove started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Delete project db2mc"
oc delete project db2mc

echo
echo ">>>>$(print_timestamp) Wait for project db2mc deletion"
wait_for_k8s_resource_disappear project/db2mc

echo
echo ">>>>$(print_timestamp) Delete DB2MC DB"
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 deactivate db DB2MC
db2 drop db DB2MC
EOSSH

echo
echo ">>>>$(print_timestamp) DB2MC remove completed"
