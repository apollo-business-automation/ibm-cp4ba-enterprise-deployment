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
echo ">>>>$(print_timestamp) PM install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Switch Project"
oc project ${CP4BA_PROJECT_NAME}

# TODO enable with 1.12 version
#echo
#echo ">>>>$(print_timestamp) Create DB user"
## Based on https://www.ibm.com/docs/en/db2/11.5?topic=ldap-managing-users
#ldap_pod=$(oc get pod -n db2 -o name | grep ldap)
#echo
#echo ">>>>$(print_timestamp) Create DB user pm"
#oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/addLdapUser.py -u pm -p ${UNIVERSAL_PASSWORD} -r user
#
#echo
#echo ">>>>$(print_timestamp) Create & configure PM Schema"
## This counts on CP4BA database created during CP4BA deployment makign this part not standalone
#oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
#su - db2inst1
#db2 CONNECT TO CP4BA;
#db2 CREATE REGULAR TABLESPACE PM_TS PAGESIZE 32 K BUFFERPOOL CP4BA_BP_32K;
#db2 CREATE USER TEMPORARY TABLESPACE PM_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
#db2 CREATE SYSTEM TEMPORARY TABLESPACE PM_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
#
#db2 GRANT DBADM ON DATABASE TO user pm;
#db2 GRANT USE OF TABLESPACE PM_TS TO user pm;
#db2 GRANT USE OF TABLESPACE PM_TEMP_TS TO user pm;
#db2 CONNECT RESET;
#EOSSH

echo
echo ">>>>$(print_timestamp) Create PM Mongo DB"
oc rsh -n mongodb-pm deployment/mongodb-pm << EOSSH
mongo --username root --password ${UNIVERSAL_PASSWORD} --authenticationDatabase admin <<EOF
use processmining
EOF
EOSSH

echo
echo ">>>>$(print_timestamp) Update DB access Secret"
sed -f - secret.yaml > secret.target.yaml << SED_SCRIPT
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Create DB access Secret"
oc apply -f secret.target.yaml

echo
echo ">>>>$(print_timestamp) Security"
# Based on https://www.ibm.com/docs/en/cloud-paks/1.0?topic=platform-ssl-certificates
oc create secret generic pm-tls-secret \
--from-file=tls.crt=../global-ca/wildcard.crt \
--from-file=tls.key=../global-ca/wildcard.key \
--from-file=ca.crt=../global-ca/global-ca.crt

echo
echo ">>>>$(print_timestamp) Update Subscription"
sed -f - subscription.yaml > subscription.target.yaml << SED_SCRIPT
s|{{PM_OPERATOR_CHANNEL}}|${PM_OPERATOR_CHANNEL}|g
s|{{PM_STARTING_CSV}}|${PM_STARTING_CSV}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Install Operator"
oc apply -f subscription.target.yaml

manage_manual_operator processmining-subscription processmining-operator-controller-manager

echo
echo ">>>>$(print_timestamp) Wait for ProcessMining CRD to be Established"
wait_for_k8s_resource_condition CustomResourceDefinition/processminings.processmining.ibm.com Established

echo
echo ">>>>$(print_timestamp) Update ProcessMining instance"
sed -f - processmining.yaml > processmining.target.yaml << SED_SCRIPT
s|{{PM_VERSION}}|${PM_VERSION}|g
s|{{MONGODB_PM_HOSTNAME}}|${MONGODB_PM_HOSTNAME}|g
s|{{DB2_HOSTNAME}}|${DB2_HOSTNAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add ProcessMining instance"
oc apply -f processmining.target.yaml

echo
echo ">>>>$(print_timestamp) Wait for ProcessMining instance Ready state"
# Validate successful deployment by following https://www.ibm.com/docs/en/cloud-paks/1.0?topic=platform-how-validate-successful-installation
wait_for_k8s_resource_condition ProcessMining/processmining Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) PM install completed"
