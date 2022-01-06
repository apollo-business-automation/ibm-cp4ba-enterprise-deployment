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
/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "${UNIVERSAL_PASSWORD}" -Q "create database [automation]; create database [knowledge]; create database [wordnet]; create database [address]; create database [audit]"
EOSSH

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
s|{{RPA_VERSION}}|${RPA_VERSION}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add RoboticProcessAutomation instance"
oc apply -f roboticprocessautomation.target.yaml

echo
echo ">>>>$(print_timestamp) Wait for RoboticProcessAutomation instance Ready state"
# Validate successful deployment by following https://www.ibm.com/docs/en/cloud-paks/1.0?topic=dependencies-validating-successful-installation
wait_for_k8s_resource_condition RoboticProcessAutomation/rpa Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for RPA UI Deployment to be Available"
wait_for_k8s_resource_condition deployment/rpa-ui-rpa Available ${DEFAULT_ATTEMPTS_1} ${DEFAULT_DELAY_1}

echo
echo ">>>>$(print_timestamp) Wait for RPA API Server Deployment to be Available"
wait_for_k8s_resource_condition deployment/rpa-apiserver-rpa Available ${DEFAULT_ATTEMPTS_1} ${DEFAULT_DELAY_1}

echo
echo ">>>>$(print_timestamp) Refresh Zen Roles"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=tasks-business-automation-studio
# TODO fix Zen permissions for Run section or wait for fix

# Get access token for ZEN administrative initial user
INITIAL_PASSWORD=`oc get secret admin-user-details -o jsonpath='{.data.initial_admin_password}' | base64 -d`
ZEN_ACCESS_TOKEN=`oc exec deployment/zen-core -- curl -k -X POST https://zen-core-api-svc:4444/openapi/v1/authorize \
--header 'Content-Type: application/json' \
--header "Accept: application/json" \
--data-raw '{
  "username": "admin",
  "password": "'${INITIAL_PASSWORD}'"
}' \
| jq -r '.token'`

DOC=`curl -k -X GET https://cpd-${CP4BA_PROJECT_NAME}.${OCP_APPS_ENDPOINT}/usermgmt/v1/roles \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $ZEN_ACCESS_TOKEN" | jq -r '.rows | map(. | select(.id=="iaf-automation-admin")) | .[] | .doc | del(._id,.extension_id,.extension_name,.updated_at)'`

curl -k -X PUT https://cpd-${CP4BA_PROJECT_NAME}.${OCP_APPS_ENDPOINT}/usermgmt/v1/role/iaf-automation-admin \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $ZEN_ACCESS_TOKEN" \
--data-raw "${DOC}"

echo
echo ">>>>$(print_timestamp) Generate RPA post deployment steps"
sed -f - postdeploy.md > postdeploy.target.md << SED_SCRIPT
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
