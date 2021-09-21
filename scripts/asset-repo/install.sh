#!/bin/bash

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) Asset Repo install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Switch Project"
oc project ${PROJECT_NAME}

echo
echo ">>>>$(print_timestamp) Install Operator"
oc apply -f subscription.yaml

echo
echo ">>>>$(print_timestamp) Wait for Operator Deployment to be Available"
wait_for_k8s_resource_condition deployment/ibm-integration-asset-repository-operator Available

echo
echo ">>>>$(print_timestamp) Update AssetRepository CR"
yq w -i assetrepository.yaml spec.storage.assetDataVolume.class "${STORAGE_CLASS_NAME}"
yq w -i assetrepository.yaml spec.storage.couchVolume.class "${STORAGE_CLASS_NAME}"

echo
echo ">>>>$(print_timestamp) Wait for AssetRepository CRD to be Established"
wait_for_k8s_resource_condition CustomResourceDefinition/assetrepositories.integration.ibm.com Established

echo
echo ">>>>$(print_timestamp) Add AssetRepository instance"
oc apply -f assetrepository.yaml

echo
echo ">>>>$(print_timestamp) Wait for AssetRepository instance Ready phase"
wait_for_k8s_resource_condition_generic AssetRepository/assets ".status.phase" Ready ${DEFAULT_ATTEMPTS_2} ${DEFAULT_DELAY_2}

echo
echo ">>>>$(print_timestamp) Add new asset repo roles to cpadmin user"
# Based on https://github.ibm.com/PrivateCloud-analytics/zen-dev-test-utils/blob/gh-pages/docs/IAM-Zen-integration.md#getting-zen-token
# Based on https://www.ibm.com/support/knowledgecenter/en/cloudpaks_start/platform-ui/1.x.x/apis/usermgmt-api-swagger.json
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=tasks-completing-post-deployment-business-automation-studio\
# Based on CP4BA demo deployment code for internal zen call

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

# Update user roles
curl -k -X PUT https://cpd-${PROJECT_NAME}.${OCP_APPS_ENDPOINT}/usermgmt/v1/user/cpadmin?add_roles=true \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $ZEN_ACCESS_TOKEN" \
--data-raw '{
  "username": "cpadmin",
  "user_roles": ["automation-assets-administrator-role",
    "automation-assets-editor-role",
    "automation-assets-viewer-role"]
}'

echo
echo ">>>>$(print_timestamp) Asset Repo install completed"