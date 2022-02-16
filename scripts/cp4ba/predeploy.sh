#!/bin/bash

# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=deployments-preparing-capabilities

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
echo ">>>>$(print_timestamp) CP4BA predeploy install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Create Project"
oc new-project ${CP4BA_PROJECT_NAME}

echo
echo ">>>>$(print_timestamp) Update Operator shared and log PVCs"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=operator-preparing-log-file-storage
sed -f - data/operator/sharedpvc.yaml > data/operator/sharedpvc.target.yaml << SED_SCRIPT
s|{{CP4BA_VERSION}}|${CP4BA_VERSION}|g
s|{{STORAGE_CLASS_NAME}}|${STORAGE_CLASS_NAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Create Operator shared PVC"
oc apply -f data/operator/sharedpvc.target.yaml

echo
echo ">>>>$(print_timestamp) Update Operator log PVC"
sed -f - data/operator/logpvc.yaml > data/operator/logpvc.target.yaml << SED_SCRIPT
s|{{CP4BA_VERSION}}|${CP4BA_VERSION}|g
s|{{STORAGE_CLASS_NAME}}|${STORAGE_CLASS_NAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Create Operator log PVC"
oc apply -f data/operator/logpvc.target.yaml

echo
echo ">>>>$(print_timestamp) Prepare pull Secrets"
oc create secret docker-registry admin.registrykey --docker-username=cp --docker-password="${ICR_PASSWORD}" --docker-server="cp.icr.io"
oc create secret docker-registry ibm-entitlement-key --docker-username=cp --docker-password="${ICR_PASSWORD}" --docker-server="cp.icr.io"

echo
echo ">>>>$(print_timestamp) Update OperatorGroup"
sed -f - data/operator/operatorgroup.yaml > data/operator/operatorgroup.target.yaml << SED_SCRIPT
s|{{CP4BA_PROJECT_NAME}}|${CP4BA_PROJECT_NAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add OperatorGroup"
oc apply -f data/operator/operatorgroup.target.yaml

echo
echo ">>>>$(print_timestamp) Update Subscription"
sed -f - data/operator/subscription.yaml > data/operator/subscription.target.yaml << SED_SCRIPT
s|{{CP4BA_OPERATOR_UPDATE_CHANNEL}}|${CP4BA_OPERATOR_UPDATE_CHANNEL}|g
s|{{CP4BA_STARTING_CSV}}|${CP4BA_STARTING_CSV}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add Subscription"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=cluster-setting-up-in-openshift-console
oc apply -f data/operator/subscription.target.yaml

manage_manual_operator ibm-cp4a-operator ibm-cp4a-operator

echo
echo ">>>>$(print_timestamp) Wait for ICP4ACluster CRD to be Established"
wait_for_k8s_resource_condition CustomResourceDefinition/icp4aclusters.icp4a.ibm.com Established

echo
echo ">>>>$(print_timestamp) Download and copy DB2 JDBC driver and license to Operator"
rm -rf jdbc
oc cp db2/c-db2ucluster-db2u-0:/opt/ibm/db2/V11.5.0.0/java/db2jcc_license_cu.jar ./jdbc/db2/db2jcc_license_cu.jar -c db2u
# DB2 driver JAR download on purpose. oc cp not used as it caused EOF errors for larger file
curl -k https://repo1.maven.org/maven2/com/ibm/db2/jcc/11.5.6.0/jcc-11.5.6.0.jar -o ./jdbc/db2/db2jcc4.jar
exit_test $? "Download DB2 drivers Failed"
OPERATOR_POD=`oc get pod -o name | grep cp4a-operator | cut -d "/" -f 2`
oc cp ./jdbc ${OPERATOR_POD}:/opt/ansible/share/jdbc

echo
echo ">>>>$(print_timestamp) Prepare custom IAF TLS secret"
oc create secret generic external-tls-secret --from-file=cert.crt=../global-ca/wildcard.crt \
--from-file=cert.key=../global-ca/wildcard.key --from-file=ca.crt=../global-ca/global-ca.crt

echo
echo ">>>>$(print_timestamp) Update AutomationUiConfig CR"
sed -f - data/iaf/automationuiconfig.yaml > data/iaf/automationuiconfig.target.yaml << SED_SCRIPT
s|{{STORAGE_CLASS_NAME}}|${STORAGE_CLASS_NAME}|g
s|{{CP4BA_AUTOMATION_UI_CONFIG_VERSION}}|${CP4BA_AUTOMATION_UI_CONFIG_VERSION}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Wait for AutomationUiConfig CRD to be Established"
wait_for_k8s_resource_condition CustomResourceDefinition/automationuiconfigs.core.automation.ibm.com Established

echo
echo ">>>>$(print_timestamp) Wait for IAF Operators Deployment to be Available"
wait_for_k8s_resource_condition deployment/iaf-core-operator-controller-manager Available
wait_for_k8s_resource_condition deployment/iaf-operator-controller-manager Available

echo
echo ">>>>$(print_timestamp) Add AutomationUiConfig instance"
# Based on https://www.ibm.com/docs/en/cloud-paks/1.0?topic=foundation-custom-resources#automationuiconfig
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=certificates-providing-root-ca-certificate Note
oc apply -f data/iaf/automationuiconfig.target.yaml

echo
echo ">>>>$(print_timestamp) Wait for AutomationUiConfig instance Ready state"
wait_for_k8s_resource_condition AutomationUiConfig/iaf-system Ready

echo
echo ">>>>$(print_timestamp) Create root CA certificate Secret"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=certificates-providing-root-ca-certificate
oc create secret tls cp4ba-root-ca --key=../global-ca/global-ca.key --cert=../global-ca/global-ca.crt

echo
echo ">>>>$(print_timestamp) Create wildcard certificate Secret"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=certificates-providing-external-routes
oc create secret tls cp4ba-wildcard --cert ../global-ca/wildcard.crt --key ../global-ca/wildcard.key
# TODO needed the same for ADP CDS pod with different name, report bug, wait for fix. roles\common\tasks\fncm\fncm-ext-tls-certification.yml doesnt ganarate this secret, CDS deployment counts on it exist. temporarily resolved by omitting external_tls_certificate_secret from main cr.yaml
# oc create secret tls cp4ba-fncm-ext-tls-secret --cert ../global-ca/wildcard.crt --key ../global-ca/wildcard.key

echo
echo ">>>>$(print_timestamp) Create LDAP bind Secret"
sed -f - data/shared/secret.yaml > data/shared/secret.target.yaml << SED_SCRIPT
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
SED_SCRIPT
oc apply -f data/shared/secret.target.yaml

echo
echo ">>>>$(print_timestamp) Resource Registry (RR) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=engine-creating-secrets-protect-sensitive-configuration-data
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=studio-creating-secrets-protect-sensitive-configuration-data

echo
echo ">>>>$(print_timestamp) RR security"
sed -f - data/rr/secret.yaml > data/rr/secret.target.yaml << SED_SCRIPT
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
SED_SCRIPT
oc apply -f data/rr/secret.target.yaml

echo
echo ">>>>$(print_timestamp) Business Automation Navigator (BAN) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=capabilities-business-automation-navigator

echo
echo ">>>>$(print_timestamp) BAN Security"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=ban-creating-secrets-protect-sensitive-business-automation-navigator-configuration-data
sed -f - data/ban/secret.yaml > data/ban/secret.target.yaml << SED_SCRIPT
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
SED_SCRIPT
oc apply -f data/ban/secret.target.yaml

echo
echo ">>>>$(print_timestamp) Business Automation Studio (BAS) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=capabilities-business-automation-studio

echo
echo ">>>>$(print_timestamp) BAS Security"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=studio-creating-secrets-protect-sensitive-configuration-data
sed -f - data/bas/secret.yaml > data/bas/secret.target.yaml << SED_SCRIPT
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
SED_SCRIPT
oc apply -f data/bas/secret.target.yaml

echo
echo ">>>>$(print_timestamp) Setup IAF AutomationBase for BAI, PFS"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=insights-customizing-kafka-elasticsearch-server-configuration
# Based on https://www.ibm.com/docs/en/cloud-paks/1.0?topic=p-system-requirements
# Based on https://github.com/IBM/automation/tree/main/cr-examples/AutomationBase
# Based on https://www.ibm.com/docs/en/cloud-paks/1.0?topic=foundation-custom-resources#automationbase

echo
echo ">>>>$(print_timestamp) Create issuer for TLS generation"
oc apply -f data/iaf/iaf-issuer.yaml

echo
echo ">>>>$(print_timestamp) Create CA certificate Secret"
# TODO dunno why but zookeeper pod cannot run if AutomationBase is not given reference to pseudo TLS secret which containes tls.crt and tls.key
oc create secret generic global-ca --from-file=ca.crt=../global-ca/global-ca.crt \
--from-file=tls.crt=../global-ca/global-ca.crt --from-file=tls.key=../global-ca/global-ca.key

echo
echo ">>>>$(print_timestamp) Create IAF admin ES user Secret"
# Based on https://www.ibm.com/docs/en/cloud-paks/1.0?topic=configuration-operational-datastore
# Username change is not described
sed -f - data/iaf/es-secret.yaml > data/iaf/es-secret.target.yaml << SED_SCRIPT
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
SED_SCRIPT
oc apply -f data/iaf/es-secret.target.yaml

echo
echo ">>>>$(print_timestamp) Update AutomationBase instance"
sed -f - data/iaf/automationbase.yaml > data/iaf/automationbase.target.yaml << SED_SCRIPT
s|{{STORAGE_CLASS_NAME}}|${STORAGE_CLASS_NAME}|g
s|{{CP4BA_AUTOMATION_BASE_VERSION}}|${CP4BA_AUTOMATION_BASE_VERSION}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add AutomationBase instance"
oc apply -f data/iaf/automationbase.target.yaml

echo
echo ">>>>$(print_timestamp) Switch to Project ibm-common-services"
oc project ibm-common-services

manage_manual_operator ibm-crossplane-operator-app ibm-crossplane

manage_manual_operator ibm-crossplane-provider-kubernetes-operator-app ibm-crossplane-provider-kubernetes-controller

echo
echo ">>>>$(print_timestamp) Wait for Events InstallPlan to be created"
wait_for_k8s_resource_condition_generic Subscription/ibm-events-operator ".status.installplan.kind" InstallPlan ${DEFAULT_ATTEMPTS_1} ${DEFAULT_DELAY_1}

echo
echo ">>>>$(print_timestamp) Approve Events InstallPlan"
install_plan=`oc get subscription ibm-events-operator -o json | jq -r '.status.installplan.name'`
oc patch installplan ${install_plan} --type merge --patch '{"spec":{"approved":true}}'

echo
echo ">>>>$(print_timestamp) Switch back to CP4BA Project"
oc project ${CP4BA_PROJECT_NAME}

echo
echo ">>>>$(print_timestamp) Wait for AutomationBase instance Ready state"
wait_for_k8s_resource_condition AutomationBase/foundation-iaf Ready ${DEFAULT_ATTEMPTS_2} ${DEFAULT_DELAY_2}

echo
echo ">>>>$(print_timestamp) Wait for Apicurio Deployment to be Available"
wait_for_k8s_resource_condition deployment/iaf-system-apicurio Available

echo
echo ">>>>$(print_timestamp) Wait for KafkaUser CRD to be Established"
wait_for_k8s_resource_condition CustomResourceDefinition/kafkausers.ibmevents.ibm.com Established

echo
echo ">>>>$(print_timestamp) Add password Secret for new KafkaUser instance"
sed -f - data/iaf/kafkauser-secret.yaml > data/iaf/kafkauser-secret.target.yaml << SED_SCRIPT
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
SED_SCRIPT
oc apply -f data/iaf/kafkauser-secret.target.yaml

echo
echo ">>>>$(print_timestamp) Add new KafkaUser instance"
# Based on https://www.ibm.com/docs/en/cloud-paks/1.0?topic=foundation-administration-guide#day-2-operations-for-kafka reference for Strimzi in Kafka Day 2
oc apply -f data/iaf/kafkauser.yaml

echo
echo ">>>>$(print_timestamp) Wait for KafkaUser instance Ready state"
wait_for_k8s_resource_condition KafkaUser/cpadmin Ready

echo
echo ">>>>$(print_timestamp) Business Automation Insights (BAI) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=capabilities-business-automation-insights

echo
echo ">>>>$(print_timestamp) Setup Stub Workforce Insights Secret"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=secrets-creating-custom-bpc-workforce-secret
rm data/bai/workforce-insights-configuration.yaml
touch data/bai/workforce-insights-configuration.yaml
oc create secret generic custom-bpc-workforce-secret --from-file=workforce-insights-configuration.yml=data/bai/workforce-insights-configuration.yaml

echo
echo ">>>>$(print_timestamp) BAI custom Secret"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=secrets-creating-custom-bai-secret
oc create secret generic custom-bai-secret \
--from-literal=kibana-username=elasticsearch-admin \
--from-literal=kibana-password=${UNIVERSAL_PASSWORD} \
--from-literal=management-username=cpadmin \
--from-literal=management-password=${UNIVERSAL_PASSWORD}

echo
echo ">>>>$(print_timestamp) Operational Decision Manager (ODM) (decisions pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=capabilities-operational-decision-manager

echo
echo ">>>>$(print_timestamp) ODM Security DB"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=capabilities-operational-decision-manager
sed -f - data/odm/secret.yaml > data/odm/secret.target.yaml << SED_SCRIPT
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
SED_SCRIPT
oc apply -f data/odm/secret.target.yaml

echo
echo ">>>>$(print_timestamp) ODM Security TLS"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=capabilities-operational-decision-manager
# Create truststore jks
rm -f data/odm/truststore.jks
keytool -import -destkeystore data/odm/truststore.jks -deststoretype jks -deststorepass ${UNIVERSAL_PASSWORD} -alias global-ca -file ../global-ca/global-ca.crt -noprompt
# Create keystore p12
openssl pkcs12 -export -out data/odm/keystore.p12 -inkey ../global-ca/wildcard.key -in ../global-ca/wildcard.crt -password pass:${UNIVERSAL_PASSWORD} -name "odm"
# Convert p12 keystore to jks
rm -f data/odm/keystore.jks
keytool -importkeystore -srckeystore data/odm/keystore.p12 -srcstoretype PKCS12 -srcstorepass ${UNIVERSAL_PASSWORD} -destkeystore data/odm/keystore.jks -deststoretype jks -deststorepass ${UNIVERSAL_PASSWORD}
# ODM Security
oc create secret generic odm-tls-secret --from-literal=keystore_password=${UNIVERSAL_PASSWORD} --from-file=keystore.jks=data/odm/keystore.jks --from-literal=truststore_password=${UNIVERSAL_PASSWORD} --from-file=truststore.jks=data/odm/truststore.jks

if [[ $CONTAINER_RUN_MODE == "true" ]]; then
  oc project automagic
  oc create cm odm-truststore --from-file=truststore.jks=data/odm/truststore.jks -o yaml --dry-run=client | oc apply -f -
  oc project ${CP4BA_PROJECT_NAME}
fi

echo
echo ">>>>$(print_timestamp) ODM Security IAM OIDC"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=access-mapping-odm-roles-iam-groups-users
# Adds cpadmin user to all roles and cpadmins to all groups.
sed -f - data/odm/webSecurity.xml > data/odm/webSecurity.target.xml << SED_SCRIPT
s|{{CP4BA_PROJECT_NAME}}|${CP4BA_PROJECT_NAME}|g
s|{{CP4BA_CR_META_NAME}}|${CP4BA_CR_META_NAME}|g
SED_SCRIPT
oc create secret generic odm-web-security-secret --from-file=webSecurity.xml=data/odm/webSecurity.target.xml --type=Opaque

echo
echo ">>>>$(print_timestamp) Automation Decision Services (ADS) (decisions_ads pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=capabilities-automation-decision-services

echo
echo ">>>>$(print_timestamp) ADS Security"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=services-configuring-decision-runtime
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=services-configuring-mongodb-storage
sed -f - data/ads/secret.yaml > data/ads/secret.target.yaml << SED_SCRIPT
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
s|{{MONGODB_HOSTNAME}}|${MONGODB_HOSTNAME}|g
SED_SCRIPT
oc apply -f data/ads/secret.target.yaml

echo
echo ">>>>$(print_timestamp) FileNet Content Manager (FNCM) (content pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=capabilities-filenet-content-manager


if [[ $EXTERNAL_SHARE_GOOGLE == "true" ]]; then
echo
echo ">>>>$(print_timestamp) FNCM ES Google API Secret"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=manager-configuring-identity-provider-connection point 4.  
oc create secret generic internal-idp-oidc-google-secret --from-literal=client_id="${GOOGLE_CLIENT_ID}" --from-literal=client_secret="${GOOGLE_CLIENT_SECRET}"

echo
echo ">>>>$(print_timestamp) FNCM ES Google API TLS"
openssl s_client -showcerts -connect accounts.google.com:443 2>/dev/null </dev/null | \
sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | awk '/-----BEGIN CERTIFICATE-----/{s=$0;next} s{s=s"\n"$0} END{print  s}' \
> data/fncm/google-tls.cer
oc create secret generic google-tls --from-file=tls.crt=data/fncm/google-tls.cer
fi

echo
echo ">>>>$(print_timestamp) FNCM Security"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=fcm-creating-secrets-protect-sensitive-filenet-content-manager-configuration-data
sed -f - data/fncm/secret.yaml > data/fncm/secret.target.yaml << SED_SCRIPT
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
SED_SCRIPT
oc apply -f data/fncm/secret.target.yaml

echo
echo ">>>>$(print_timestamp) Automation Application Engine (AAE) (application pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=capabilities-application-engine

echo
echo ">>>>$(print_timestamp) AAE Security"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=engine-creating-secrets-protect-sensitive-configuration-data
sed -f - data/aae/secret.yaml > data/aae/secret.target.yaml << SED_SCRIPT
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
SED_SCRIPT
oc apply -f data/aae/secret.target.yaml

# If you plan to use AAE data persistence, you need to update FNCM secret for new object store. 
# Make sure FNCM secret already exists
oc patch secret ibm-fncm-secret -p '{"data": {"aeosDBUsername": "'$(echo -n aeos | base64)'","aeosDBPassword": "'$(echo -n ${UNIVERSAL_PASSWORD} | base64)'"}}'

echo
echo ">>>>$(print_timestamp) Automation Document Processing (ADP) (document_processing pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=capabilities-document-processing

echo
echo ">>>>$(print_timestamp) ADP Security"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=dp-creating-secrets-protect-sensitive-document-processing-configuration-data
sed -f - data/adp/secret.yaml > data/adp/secret.target.yaml << SED_SCRIPT
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
s|{{MONGODB_HOSTNAME}}|${MONGODB_HOSTNAME}|g
SED_SCRIPT
oc apply -f data/adp/secret.target.yaml
# Update FNCM secret
oc patch secret ibm-fncm-secret -p '{"data": {"devos1DBUsername": "'$(echo -n devos1 | base64)'","devos1DBPassword": "'$(echo -n ${UNIVERSAL_PASSWORD} | base64)'"}}'

echo
echo ">>>>$(print_timestamp) Business Automation Workflow Authoring (BAWAUT)"

echo
echo ">>>>$(print_timestamp) BAWAUT Security"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=authoring-creating-secrets-protect-sensitive-configuration-data
sed -f - data/bawaut/secret.yaml > data/bawaut/secret.target.yaml << SED_SCRIPT
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
SED_SCRIPT
oc apply -f data/bawaut/secret.target.yaml
# Update FNCM secret
oc patch secret ibm-fncm-secret -p '{"data": {"badocsDBUsername": "'$(echo -n badocs | base64)'","badocsDBPassword": "'$(echo -n ${UNIVERSAL_PASSWORD} | base64)'"}}'
oc patch secret ibm-fncm-secret -p '{"data": {"batosDBUsername": "'$(echo -n batos | base64)'","batosDBPassword": "'$(echo -n ${UNIVERSAL_PASSWORD} | base64)'"}}'
oc patch secret ibm-fncm-secret -p '{"data": {"badosDBUsername": "'$(echo -n bados | base64)'","badosDBPassword": "'$(echo -n ${UNIVERSAL_PASSWORD} | base64)'"}}'

# Update FNCM secret for new Case History connection.
# Make sure FNCM secret already exists
oc patch secret ibm-fncm-secret -p '{"data": {"chDBUsername": "'$(echo -n ch | base64)'","chDBPassword": "'$(echo -n ${UNIVERSAL_PASSWORD} | base64)'"}}'

echo
echo ">>>>$(print_timestamp) BAWAUT Security for Email notifications"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=services-optional-customizing-runtime-server-properties
# Based on https://www.ibm.com/docs/en/baw/20.x?topic=work-configuring-email-notifications
# Based on https://www.ibm.com/docs/en/baw/20.x?topic=configuration-creating-100customxml-file
sed -f - data/bawaut/100Custom.xml > data/bawaut/100Custom.target.xml << SED_SCRIPT
s|{{MAIL_HOSTNAME}}|${MAIL_HOSTNAME}|g
SED_SCRIPT
oc create secret generic wfs-lombardi-custom-xml-secret --from-file=sensitiveCustomConfig=data/bawaut/100Custom.target.xml

echo
echo ">>>>$(print_timestamp) CP4BA predeploy install completed"
