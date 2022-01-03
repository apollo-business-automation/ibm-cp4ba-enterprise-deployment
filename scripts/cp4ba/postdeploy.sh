#!/bin/bash

# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=deployments-completing-post-installation-tasks

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
echo ">>>>$(print_timestamp) CP4BA postdeploy install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Switch Project"
oc project ${CP4BA_PROJECT_NAME}

echo
echo ">>>>$(print_timestamp) Business Automation Navigator (BAN) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=tasks-business-automation-navigator

echo
echo ">>>>$(print_timestamp) Copy Daeja license"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=tasks-business-automation-navigator point 2.  
# License files generated following https://www.ibm.com/docs/en/daeja-viewone/5.0.x?topic=modules-enabling-viewer-add-in-content-navigator
# IBM Daeja ViewONE Virtual Permanent Redaction Server Module & IBM Daeja ViewONE Virtual Module for Microsoft Office are part of CP4BA as per LI at http://www-03.ibm.com/software/sla/sladb.nsf/lilookup/31BA4BF94C59AD55852586FE0060B39C?OpenDocument
BAN_POD=`oc get pod -o name | grep navigator | cut -d "/" -f 2`
oc cp data/ban/lic-server-virtual.v1 ${BAN_POD}:/opt/ibm/wlp/usr/servers/defaultServer/configDropins/overrides/
oc cp data/ban/lic-server.v1 ${BAN_POD}:/opt/ibm/wlp/usr/servers/defaultServer/configDropins/overrides/

echo
echo ">>>>$(print_timestamp) Business Automation Studio (BAS) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=tasks-business-automation-studio

echo
echo ">>>>$(print_timestamp) Add cpadmin user to ZEN UI"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=tasks-business-automation-studio

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

# Add all roles to  cpadmin user
curl -k -X PUT https://cpd-${CP4BA_PROJECT_NAME}.${OCP_APPS_ENDPOINT}/usermgmt/v1/user/cpadmin?add_roles=true \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $ZEN_ACCESS_TOKEN" \
--data-raw '{
  "username": "cpadmin",
  "user_roles": ["zen_administrator_role","iaf-automation-admin","iaf-automation-analyst","iaf-automation-developer","iaf-automation-operator","zen_user_role"]
}'

echo
echo ">>>>$(print_timestamp) Get IAM access token"
# Based on https://www.ibm.com/docs/en/cpfs?topic=apis-oidc-registration#get2 (Get access token by using username and password)
ACCESS_TOKEN=`curl -k -X POST -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" \
-d "grant_type=password&username=cpadmin&password=${UNIVERSAL_PASSWORD}&scope=openid" \
https://cp-console.${OCP_APPS_ENDPOINT}/idprovider/v1/auth/identitytoken \
| jq -r '.access_token'`

echo
echo ">>>>$(print_timestamp) Exchange IAM access token for Zen token"
TOKEN=$(curl -sk "https://cpd-${CP4BA_PROJECT_NAME}.${OCP_APPS_ENDPOINT}/v1/preauth/validateAuth" -H "username:cpadmin" -H "iam-token: $ACCESS_TOKEN" | jq -r .accessToken)

echo
echo ">>>>$(print_timestamp) Business Automation Insights (BAI) (foundation pattern)"

echo
echo ">>>>$(print_timestamp) Update Workforce Insights Secret"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=secrets-creating-custom-bpc-workforce-secret
curl --insecure --request GET https://cpd-${CP4BA_PROJECT_NAME}.${OCP_APPS_ENDPOINT}/pfs/rest/bpm/federated/v1/systems \
--header "Authorization: Bearer $TOKEN" \
| jq '.systems | map(. | select(.systemType=="SYSTEM_TYPE_WLE")) | map(. |= {"systemID", "hostname"}) | [.[] | .["bpmSystemId"] = .systemID | .["url"] = ("https://cpd-'${CP4BA_PROJECT_NAME}.${OCP_APPS_ENDPOINT}'/bawaut") | .["username"] = "cpadmin" | .["password"] = "'${UNIVERSAL_PASSWORD}'" | del(.systemID,.hostname)]' \
> data/bai/workforce-insights-configuration.json

yq r --prettyPrint data/bai/workforce-insights-configuration.json > data/bai/workforce-insights-configuration.yaml
oc patch secret custom-bpc-workforce-secret -p '{"data": {"workforce-insights-configuration.yml": "'$(base64 -w 0 data/bai/workforce-insights-configuration.yaml)'"}}'

echo
echo ">>>>$(print_timestamp) Delete BPC pods"
oc get pods -o name | grep iaf-insights-engine-cockpit | xargs oc delete

echo
echo ">>>>$(print_timestamp) Wait for BPC Deployment Available state"
wait_for_k8s_resource_condition Deployment/iaf-insights-engine-cockpit Available

echo
echo ">>>>$(print_timestamp) Operational Decision Manager (ODM) (decisions pattern)"

echo
echo ">>>>$(print_timestamp) Replace OIDC providers file with real values"
sed -f - data/odm/oidc-providers.json > data/odm/oidc-providers.target.json << SED_SCRIPT
s|{{CP4BA_CR_META_NAME}}|${CP4BA_CR_META_NAME}|g
s|{{OCP_APPS_ENDPOINT}}|${OCP_APPS_ENDPOINT}|g
SED_SCRIPT

if [[ $CONTAINER_RUN_MODE == "true" ]]; then
  oc project automagic
  oc create cm odm-oidc-providers --from-file=oidc-providers.json=data/odm/oidc-providers.target.json -o yaml --dry-run=client | oc apply -f -
  oc project ${CP4BA_PROJECT_NAME}
fi

echo
echo ">>>>$(print_timestamp) Automation Decision Services (ADS) (decisions_ads pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=tasks-automation-decision-services

echo
echo ">>>>$(print_timestamp) Create ADS organization in Gitea"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=gst-task-2-connecting-git-repository-sharing-decision-service
curl --insecure --request POST "https://gitea.${OCP_APPS_ENDPOINT}/api/v1/orgs" \
--header  "Content-Type: application/json" \
--user "cpadmin:${UNIVERSAL_PASSWORD}" \
--data-raw '
{
  "description": "",
  "full_name": "",
  "location": "",
  "repo_admin_change_team_access": true,
  "username": "ads",
  "visibility": "private",
  "website": ""
}
'

echo
echo ">>>>$(print_timestamp) Download ADS Maven plugins and push them to Nexus"
# Download maven plugins definition
curl --insecure --request GET "https://cpd-${CP4BA_PROJECT_NAME}.${OCP_APPS_ENDPOINT}/ads/download/index.json" \
--header "Authorization: Bearer $TOKEN" --output data/ads/index.json

# Download and push annotations_maven_plugin
JAR_PATH=$(cat data/ads/index.json | jq -r '.resources.annotations_maven_plugin.path')
curl --insecure https://cpd-${CP4BA_PROJECT_NAME}.${OCP_APPS_ENDPOINT}/ads/download/$JAR_PATH --output data/ads/$JAR_PATH \
--header "Authorization: Bearer $TOKEN"
JAR_SUB="${JAR_PATH:0:(-4)}"  
ARTIFACT_ID=`echo $JAR_SUB | cut -d "_" -f 1`
VERSION=`echo $JAR_SUB | cut -d "_" -f 2`

mvn --s ~/.m2/settings.xml deploy:deploy-file -Dmaven.wagon.http.ssl.insecure=true -DgroupId=com.ibm.decision -DartifactId=$ARTIFACT_ID \
-Dversion=$VERSION -Dpackaging=jar -DrepositoryId=nexus \
-Durl=https://nexus.${OCP_APPS_ENDPOINT}/repository/maven-releases/ -Dfile=data/ads/$JAR_PATH

# Download and push foundation_maven_plugin
JAR_PATH=$(cat data/ads/index.json | jq -r '.resources.foundation_maven_plugin.path')
curl --insecure https://cpd-${CP4BA_PROJECT_NAME}.${OCP_APPS_ENDPOINT}/ads/download/$JAR_PATH --output data/ads/$JAR_PATH \
--header "Authorization: Bearer $TOKEN"
JAR_SUB="${JAR_PATH:0:(-4)}"  
ARTIFACT_ID=`echo $JAR_SUB | cut -d "_" -f 1`
VERSION=`echo $JAR_SUB | cut -d "_" -f 2`

mvn --s ~/.m2/settings.xml deploy:deploy-file -Dmaven.wagon.http.ssl.insecure=true -DgroupId=com.ibm.decision -DartifactId=$ARTIFACT_ID \
-Dversion=$VERSION -Dpackaging=jar -DrepositoryId=nexus \
-Durl=https://nexus.${OCP_APPS_ENDPOINT}/repository/maven-releases/ -Dfile=data/ads/$JAR_PATH

# Download and push build_command_maven_plugin
JAR_PATH=$(cat data/ads/index.json | jq -r '.resources.build_command_maven_plugin.path')
curl --insecure https://cpd-${CP4BA_PROJECT_NAME}.${OCP_APPS_ENDPOINT}/ads/download/$JAR_PATH -o data/ads/$JAR_PATH \
--header "Authorization: Bearer $TOKEN"
JAR_SUB="${JAR_PATH:0:(-4)}"  
ARTIFACT_ID=`echo $JAR_SUB | cut -d "_" -f 1`
VERSION=`echo $JAR_SUB | cut -d "_" -f 2`

mvn --s ~/.m2/settings.xml deploy:deploy-file -Dmaven.wagon.http.ssl.insecure=true -DgroupId=com.ibm.decision -DartifactId=$ARTIFACT_ID \
-Dversion=$VERSION -Dpackaging=jar -DrepositoryId=nexus \
-Durl=https://nexus.${OCP_APPS_ENDPOINT}/repository/maven-releases/ -Dfile=data/ads/$JAR_PATH

# Download and push import_maven_plugin
JAR_PATH=$(cat data/ads/index.json | jq -r '.resources.import_maven_plugin.path')
curl --insecure https://cpd-${CP4BA_PROJECT_NAME}.${OCP_APPS_ENDPOINT}/ads/download/$JAR_PATH -o data/ads/$JAR_PATH \
--header "Authorization: Bearer $TOKEN"
JAR_SUB="${JAR_PATH:0:(-4)}"  
ARTIFACT_ID=`echo $JAR_SUB | cut -d "_" -f 1`
VERSION=`echo $JAR_SUB | cut -d "_" -f 2`

mvn --s ~/.m2/settings.xml deploy:deploy-file -Dmaven.wagon.http.ssl.insecure=true -DgroupId=com.ibm.decision -DartifactId=$ARTIFACT_ID \
-Dversion=$VERSION -Dpackaging=jar -DrepositoryId=nexus \
-Durl=https://nexus.${OCP_APPS_ENDPOINT}/repository/maven-releases/ -Dfile=data/ads/$JAR_PATH

# Download and push import_maven_archetype_plugin
JAR_PATH=$(cat data/ads/index.json | jq -r '.resources.import_maven_archetype_plugin.path')
curl --insecure https://cpd-${CP4BA_PROJECT_NAME}.${OCP_APPS_ENDPOINT}/ads/download/$JAR_PATH -o data/ads/$JAR_PATH \
--header "Authorization: Bearer $TOKEN"
JAR_SUB="${JAR_PATH:0:(-4)}"  
ARTIFACT_ID=`echo $JAR_SUB | cut -d "_" -f 1`
VERSION=`echo $JAR_SUB | cut -d "_" -f 2`

mvn --s ~/.m2/settings.xml deploy:deploy-file -Dmaven.wagon.http.ssl.insecure=true -DgroupId=com.ibm.decision -DartifactId=$ARTIFACT_ID \
-Dversion=$VERSION -Dpackaging=jar -DrepositoryId=nexus \
-Durl=https://nexus.${OCP_APPS_ENDPOINT}/repository/maven-releases/ -Dfile=data/ads/$JAR_PATH

# Download and push engine_maven_plugin
JAR_PATH=$(cat data/ads/index.json | jq -r '.resources.engine_maven_plugin.path')
curl --insecure https://cpd-${CP4BA_PROJECT_NAME}.${OCP_APPS_ENDPOINT}/ads/download/$JAR_PATH -o data/ads/$JAR_PATH \
--header "Authorization: Bearer $TOKEN"
JAR_SUB="${JAR_PATH:0:(-4)}"  
ARTIFACT_ID=`echo $JAR_SUB | cut -d "_" -f 1`
VERSION=`echo $JAR_SUB | cut -d "_" -f 2`

mvn --s ~/.m2/settings.xml deploy:deploy-file -Dmaven.wagon.http.ssl.insecure=true -DgroupId=com.ibm.decision -DartifactId=$ARTIFACT_ID \
-Dversion=$VERSION -Dpackaging=jar -DrepositoryId=nexus \
-Durl=https://nexus.${OCP_APPS_ENDPOINT}/repository/maven-releases/ -Dfile=data/ads/$JAR_PATH

# Download and push ml_integration_maven_plugin
JAR_PATH=$(cat data/ads/index.json | jq -r '.resources.ml_integration_maven_plugin.path')
curl --insecure https://cpd-${CP4BA_PROJECT_NAME}.${OCP_APPS_ENDPOINT}/ads/download/$JAR_PATH -o data/ads/$JAR_PATH \
--header "Authorization: Bearer $TOKEN"
JAR_SUB="${JAR_PATH:0:(-4)}"  
ARTIFACT_ID=`echo $JAR_SUB | cut -d "_" -f 1`
VERSION=`echo $JAR_SUB | cut -d "_" -f 2`

mvn --s ~/.m2/settings.xml deploy:deploy-file -Dmaven.wagon.http.ssl.insecure=true -DgroupId=com.ibm.decision -DartifactId=$ARTIFACT_ID \
-Dversion=$VERSION -Dpackaging=jar -DrepositoryId=nexus \
-Durl=https://nexus.${OCP_APPS_ENDPOINT}/repository/maven-releases/ -Dfile=data/ads/$JAR_PATH

echo
echo ">>>>$(print_timestamp) Create ADS Admin custom Role and assign it to cpadmin to be able to manage ADS platform credentials"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=services-managing-user-permissions

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

# Create ADS admin role
ROLE_ID=`curl -k -X POST https://cpd-${CP4BA_PROJECT_NAME}.${OCP_APPS_ENDPOINT}/usermgmt/v1/role \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $ZEN_ACCESS_TOKEN" \
--data-raw '{"role_name":"ADS Admin","description":"","permissions":["administer_ads_platform","execute_ads_decision","manage_ads_decision","monitor_ads_runtime"]}' | jq -r '.id'`

# Update user roles
curl -k -X PUT https://cpd-${CP4BA_PROJECT_NAME}.${OCP_APPS_ENDPOINT}/usermgmt/v1/user/cpadmin?add_roles=true \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $ZEN_ACCESS_TOKEN" \
--data-raw '{
  "username": "cpadmin",
  "user_roles": ["'${ROLE_ID}'"]
}'

#TODO how to refresh groups?
#echo
#echo ">>>>$(print_timestamp) Add Maven credential"
## Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=credentials-configuring-maven-repository-manager
curl -k -X POST https://cpd-${CP4BA_PROJECT_NAME}.${OCP_APPS_ENDPOINT}/ads/rest-api/api/admin/credential \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $TOKEN" \
--data-raw '{"credentialsType":"USERNAME","credentialsUsage":"MAVEN","discriminator":"https://nexus.'${OCP_APPS_ENDPOINT}'/repository/maven-releases/ ","credentials":"cpadmin:'${UNIVERSAL_PASSWORD}'"}'

echo
echo ">>>>$(print_timestamp) Automation Document Processing (ADP) (document_processing pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=tasks-document-processing

echo
echo ">>>>$(print_timestamp) Create ADP organization in Gitea"
curl --insecure --request POST "https://gitea.${OCP_APPS_ENDPOINT}/api/v1/orgs" \
--header  "Content-Type: application/json" \
--user "cpadmin:${UNIVERSAL_PASSWORD}" \
--data-raw '
{
  "description": "",
  "full_name": "",
  "location": "",
  "repo_admin_change_team_access": true,
  "username": "adp",
  "visibility": "private",
  "website": ""
}
'

echo
echo ">>>>$(print_timestamp) Download Init Tenants scripts"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=processing-loading-default-sample-data
nle_pod=$(oc get po | grep natural-language-extractor | awk {'print $1'} | head -1)
oc cp $nle_pod:/data-org/db_sample_data/imports.tar.xz data/adp/imports.tar.xz

echo
echo ">>>>$(print_timestamp) Copy Init Tenants scripts to DB2"
oc cp data/adp/imports.tar.xz db2/c-db2ucluster-db2u-0:/tmp/imports.tar.xz -c db2u
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
sudo mv /tmp/imports.tar.xz /mnt/blumeta0/home/db2inst1/sqllib/_adp_tmp/DB2/imports.tar.xz
sudo chown -R db2inst1:db2iadm1 /mnt/blumeta0/home/db2inst1/sqllib/_adp_tmp/DB2/imports.tar.xz
EOSSH

echo
echo ">>>>$(print_timestamp) Extract and run Init Tenants scripts"
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
cd sqllib/_adp_tmp/DB2
tar -xvf imports.tar.xz
chmod +x LoadDefaultData.sh

# Init TENANT1 DB
echo "TENANT1
default
y" | ./LoadDefaultData.sh

# Init TENANT2 DB
echo "TENANT2
default
y" | ./LoadDefaultData.sh
EOSSH

echo
echo ">>>>$(print_timestamp) ADP remove DB init files"
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
rm -rf sqllib/_adp_tmp
EOSSH

# TODO maybe later - CSRF rejected error
#echo
#echo ">>>>$(print_timestamp) ADP setup Git connection"
## Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=processing-setting-up-remote-git-organization
#curl -k -X POST https://cpd-${CP4BA_PROJECT_NAME}.${OCP_APPS_ENDPOINT}/adp/designer/api/cd/v1/credentials \
#--header 'Content-Type: application/json' \
#--header "Authorization: Bearer $TOKEN" \
#--data-raw '{"uri":"https://gitea.'${OCP_APPS_ENDPOINT}'/adp","user_id":"cpadmin","type":"password","secret":"'${UNIVERSAL_PASSWORD}'","provider":"gitea"}'

echo
echo ">>>>$(print_timestamp) Generate CP4BA post deployment steps"
sed -f - postdeploy.md > postdeploy.target.md << SED_SCRIPT
s|{{OCP_APPS_ENDPOINT}}|${OCP_APPS_ENDPOINT}|g
s|{{CP4BA_PROJECT_NAME}}|${CP4BA_PROJECT_NAME}|g
s|{{OCP_API_ENDPOINT}}|${OCP_API_ENDPOINT}|g
s|{{OCP_CLUSTER_ADMIN}}|${OCP_CLUSTER_ADMIN}|g
s|{{OCP_CLUSTER_ADMIN_PASSWORD}}|${OCP_CLUSTER_ADMIN_PASSWORD}|g
s|{{OCP_CLUSTER_TOKEN}}|${OCP_CLUSTER_TOKEN}|g
s|{{MAIL_HOSTNAME}}|${MAIL_HOSTNAME}|g
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
SED_SCRIPT


if [[ $CONTAINER_RUN_MODE == "true" ]]; then
  oc project automagic
  oc create cm cp4ba-postdeploy --from-file=postdeploy.md=postdeploy.target.md -o yaml --dry-run=client | oc apply -f -
fi

echo
echo ">>>>$(print_timestamp) CP4BA postdeploy install completed"
