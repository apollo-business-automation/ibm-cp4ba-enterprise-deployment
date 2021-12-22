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
echo ">>>>$(print_timestamp) CP4BA remove started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Force delete Project cp4ba"
./force-uninstall.sh -n ${CP4BA_PROJECT_NAME}

echo
echo ">>>>$(print_timestamp) Wait for project cp4ba deletion"
wait_for_k8s_resource_disappear project/${CP4BA_PROJECT_NAME}

echo
echo ">>>>$(print_timestamp) Remove DBs from DB2MC"

echo
echo ">>>>$(print_timestamp) Get auth token"
AUTH_TOKEN=`curl -k -X POST \
https://db2mc.${OCP_APPS_ENDPOINT}/dbapi/v4/auth/tokens \
-H 'content-type: application/json' \
-d '{"userid":"cpadmin","password":"'${UNIVERSAL_PASSWORD}'"}' | jq -r '.token'`

echo
echo ">>>>$(print_timestamp) Remove DB connections from DB2MC"
remove_db2mc_connection CP4BA
remove_db2mc_connection TENANT1
remove_db2mc_connection TENANT2

echo
echo ">>>>$(print_timestamp) Delete DBs"
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 deactivate db CP4BA
db2 drop db CP4BA
db2 deactivate db TENANT1
db2 drop db TENANT1
db2 deactivate db TENANT2
db2 drop db TENANT2
EOSSH

echo
echo ">>>>$(print_timestamp) Delete DB users"
# Based on https://www.ibm.com/docs/en/db2/11.5?topic=ldap-managing-users
ldap_pod=$(oc get pod -n db2 -o name | grep ldap)
echo
echo ">>>>$(print_timestamp) Delete DB user icndb"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/removeLdapUser.py -u icndb
echo
echo ">>>>$(print_timestamp) Delete DB user pb"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/removeLdapUser.py -u pb
echo
echo ">>>>$(print_timestamp) Delete DB user bas"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/removeLdapUser.py -u bas
echo
echo ">>>>$(print_timestamp) Delete DB user odm"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/removeLdapUser.py -u odm
echo
echo ">>>>$(print_timestamp) Delete DB user gcd"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/removeLdapUser.py -u gcd
echo
echo ">>>>$(print_timestamp) Delete DB user os1"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/removeLdapUser.py -u os1
echo
echo ">>>>$(print_timestamp) Delete DB user aae"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/removeLdapUser.py -u aae
echo
echo ">>>>$(print_timestamp) Delete DB user aeos"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/removeLdapUser.py -u aeos
echo
echo ">>>>$(print_timestamp) Delete DB user base"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/removeLdapUser.py -u base
echo
echo ">>>>$(print_timestamp) Delete DB user devos1"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/removeLdapUser.py -u devos1
echo
echo ">>>>$(print_timestamp) Delete DB user badocs"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/removeLdapUser.py -u badocs
echo
echo ">>>>$(print_timestamp) Delete DB user batos"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/removeLdapUser.py -u batos
echo
echo ">>>>$(print_timestamp) Delete DB user bados"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/removeLdapUser.py -u bados
echo
echo ">>>>$(print_timestamp) Delete DB user bawaut"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/removeLdapUser.py -u bawaut
echo
echo ">>>>$(print_timestamp) Delete DB user ch"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/removeLdapUser.py -u ch

echo
echo ">>>>$(print_timestamp) Delete Mongo DBs"
oc rsh -n mongodb deployment/mongodb << EOSSH
mongo --username root --password ${UNIVERSAL_PASSWORD} --authenticationDatabase admin <<EOF
use ads
db.dropDatabase()
use ads-git
db.dropDatabase()
use ads-history
db.dropDatabase()
use ads-runtime
db.dropDatabase()
EOF
EOSSH

echo
echo ">>>>$(print_timestamp) Remove ADS organization in Gitea if empty"
curl --insecure --request DELETE "https://gitea.${OCP_APPS_ENDPOINT}/api/v1/orgs/ads" \
--header  "Content-Type: application/json" \
--user "cpadmin:${UNIVERSAL_PASSWORD}"

echo
echo ">>>>$(print_timestamp) Remove ADP organization in Gitea if empty"
curl --insecure --request DELETE "https://gitea.${OCP_APPS_ENDPOINT}/api/v1/orgs/adp" \
--header  "Content-Type: application/json" \
--user "cpadmin:${UNIVERSAL_PASSWORD}"

echo
echo ">>>>$(print_timestamp) CP4BA remove completed"
