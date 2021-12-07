#!/bin/bash

# Based on https://www.ibm.com/docs/en/cloud-paks/1.0?topic=foundation-robotic-process-automation

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
echo ">>>>$(print_timestamp) RPA install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Switch Project"
oc project ${CP4BA_PROJECT_NAME}

echo
echo ">>>>$(print_timestamp) Update Subscription"
sed -f - subscription.yaml > subscription.target.yaml << SED_SCRIPT
s|{{RPA_OPERATOR_CHANNEL}}|${RPA_OPERATOR_CHANNEL}|g
s|{{RPA_STARTING_CSV}}|${RPA_STARTING_CSV}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Install Operator"
oc apply -f subscription.target.yaml

manage_manual_operator rpa-subscription ibm-rpa-operator-controller-manager

echo
echo ">>>>$(print_timestamp) Wait for ProcessMining CRD to be Established"
wait_for_k8s_resource_condition CustomResourceDefinition/roboticprocessautomations.rpa.automation.ibm.com Established

echo
echo ">>>>$(print_timestamp) Prepare MSSQL DBs"
oc rsh -n mssql deployment/mssql << EOSSH
/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "${UNIVERSAL_PASSWORD}" -Q "create database [automation]; create database [knowledge]; create database [wordnet]; create database [address]"
EOSSH

echo
echo ">>>>$(print_timestamp) Prepare IAM Teams"
# Based on https://www.ibm.com/docs/en/cpfs?topic=apis-team-management#create
# Based on https://www.ibm.com/docs/en/cloud-paks/1.0?topic=users-configuring-ldap-connection
# Based on https://www.ibm.com/docs/en/cpfs?topic=apis-directory-management#import for import

# Get access token for administrative user
ACCESS_TOKEN=`curl -k -X POST -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" \
-d "grant_type=password&username=cpfsadmin&password=${UNIVERSAL_PASSWORD}&scope=openid" \
https://cp-console.${OCP_APPS_ENDPOINT}/idprovider/v1/auth/identitytoken \
| jq -r '.access_token'`

# Get LDAP ID
LDAP_ID=`curl -k -X GET --header "Authorization: Bearer $ACCESS_TOKEN" \
"https://cp-console.${OCP_APPS_ENDPOINT}/idmgmt/identity/api/v1/directory/ldap/list" | jq -r '.[0].id'`

# Import cpusers user groups
curl -k -X POST --header "Authorization: Bearer $ACCESS_TOKEN" \
--header 'Content-Type: application/json' \
-d '{ "baseDN": "cn=cpusers,ou=Groups,dc=cp" }' \
"https://cp-console.${OCP_APPS_ENDPOINT}/idmgmt/identity/api/v1/directory/ldap/${LDAP_ID}/importUserGroups"

# Add rpa-users team
curl -k -X POST --header "Authorization: bearer $ACCESS_TOKEN" \
--header 'Content-Type: application/json' \
-d '{"teamId": "rpa-users", "name": "rpa-users", 
"usergroups": [{"name":"cpusers","userGroupDN":"cn=cpusers,ou=Groups,dc=cp","roles":[{"id":"crn:v1:icp:private:iam::::role:Administrator"}]}]}' \
"https://cp-console.${OCP_APPS_ENDPOINT}/idmgmt/identity/api/v1/teams/"

# Import cpadmins user groups
curl -k -X POST --header "Authorization: Bearer $ACCESS_TOKEN" \
--header 'Content-Type: application/json' \
-d '{ "baseDN": "cn=cpadmins,ou=Groups,dc=cp" }' \
"https://cp-console.${OCP_APPS_ENDPOINT}/idmgmt/identity/api/v1/directory/ldap/${LDAP_ID}/importUserGroups"

# Add rpa-admins team
curl -k -X POST --header "Authorization: bearer $ACCESS_TOKEN" \
--header 'Content-Type: application/json' \
-d '{"teamId": "rpa-admins", "name": "rpa-admins", 
"usergroups": [{"name":"cpadmins","userGroupDN":"cn=cpadmins,ou=Groups,dc=cp","roles":[{"id":"crn:v1:icp:private:iam::::role:Administrator"}]}]}' \
"https://cp-console.${OCP_APPS_ENDPOINT}/idmgmt/identity/api/v1/teams/"

# Add rpa-superadmins team
curl -k -X POST --header "Authorization: bearer $ACCESS_TOKEN" \
--header 'Content-Type: application/json' \
-d '{"teamId": "rpa-superadmins", "name": "rpa-superadmins", 
"usergroups": [{"name":"cpadmins","userGroupDN":"cn=cpadmins,ou=Groups,dc=cp","roles":[{"id":"crn:v1:icp:private:iam::::role:Administrator"}]}]}' \
"https://cp-console.${OCP_APPS_ENDPOINT}/idmgmt/identity/api/v1/teams/"

echo
echo ">>>>$(print_timestamp) Update Secrets"
sed -f - secrets.yaml > secrets.target.yaml << SED_SCRIPT
s|{{MSSQL_HOSTNAME}}|${MSSQL_HOSTNAME}|g
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Create Secrets"
oc apply -f secrets.target.yaml

echo
echo ">>>>$(print_timestamp) Update RoboticProcessAutomation instance"
sed -f - roboticprocessautomation.yaml > roboticprocessautomation.target.yaml << SED_SCRIPT
s|{{STORAGE_CLASS_NAME}}|${STORAGE_CLASS_NAME}|g
s|{{MAIL_HOSTNAME}}|${MAIL_HOSTNAME}|g
SED_SCRIPT


if [ "$DEPLOYMENT_PLATFORM" = "ROKS" ]; then
echo
echo ">>>>$(print_timestamp) Add permissive Egress NetworkPolicy for RPA API server"
# TODO remove when ROKS officially supported and working
  oc apply -f netwrokpolicy-hotfix.yaml
fi

echo
echo ">>>>$(print_timestamp) Add RoboticProcessAutomation instance"
oc apply -f roboticprocessautomation.target.yaml

echo
echo ">>>>$(print_timestamp) Wait for RoboticProcessAutomation instance Ready state"
# Validate successful deployment by following https://www.ibm.com/docs/en/cloud-paks/1.0?topic=automation-validating-successful-installation
wait_for_k8s_resource_condition RoboticProcessAutomation/rpa Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for RPA UI Deployment to be Available"
wait_for_k8s_resource_condition deployment/rpa-ui-rpa Available ${DEFAULT_ATTEMPTS_1} ${DEFAULT_DELAY_1}

echo
echo ">>>>$(print_timestamp) Wait for RPA API Server Deployment to be Available"
wait_for_k8s_resource_condition deployment/rpa-apiserver-rpa Available ${DEFAULT_ATTEMPTS_1} ${DEFAULT_DELAY_1}

# TODO fix Zen permissions for Run section or wait for fix

echo
echo ">>>>$(print_timestamp) Generate RPA post deployment steps"
sed -f - postdeploy.yaml > postdeploy.target.yaml << SED_SCRIPT
s|{{OCP_APPS_ENDPOINT}}|${OCP_APPS_ENDPOINT}|g
s|{{CP4BA_PROJECT_NAME}}|${CP4BA_PROJECT_NAME}|g
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
SED_SCRIPT

if [[ $CONTAINER_RUN_MODE == "true" ]]; then
  oc project automagic
  oc create cm rpa-postdeploy --from-file=postdeploy.md=postdeploy.target.md -o yaml --dry-run=client | oc apply -f -
fi

echo
echo ">>>>$(print_timestamp) RPA install completed"
