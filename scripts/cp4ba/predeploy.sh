#!/bin/bash

# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=deployments-preparing-enterprise-deployment

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
oc new-project ${PROJECT_NAME}

echo
echo ">>>>$(print_timestamp) Update Operator shared and log PVCs"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=operator-preparing-log-file-storage
yq w -i data/operator/sharedpvc.yaml metadata.labels.release "${CP4BA_VERSION}"
yq w -i data/operator/sharedpvc.yaml spec.storageClassName "${STORAGE_CLASS_NAME}"
yq w -i data/operator/logpvc.yaml metadata.labels.release "${CP4BA_VERSION}"

echo
echo ">>>>$(print_timestamp) Create Operator shared PVC"
oc apply -f data/operator/sharedpvc.yaml

echo
echo ">>>>$(print_timestamp) Update Operator log PVC"
yq w -i data/operator/logpvc.yaml metadata.labels.release "${CP4BA_VERSION}"
yq w -i data/operator/logpvc.yaml spec.storageClassName "${STORAGE_CLASS_NAME}"

echo
echo ">>>>$(print_timestamp) Create Operator log PVC"
oc apply -f data/operator/logpvc.yaml

echo
echo ">>>>$(print_timestamp) Prepare pull Secrets"
oc create secret docker-registry admin.registrykey --docker-username=cp --docker-password="${ICR_PASSWORD}" --docker-server="cp.icr.io"
oc create secret docker-registry ibm-entitlement-key --docker-username=cp --docker-password="${ICR_PASSWORD}" --docker-server="cp.icr.io"

echo
echo ">>>>$(print_timestamp) Update OperatorGroup"
yq w -i data/operator/operatorgroup.yaml spec.targetNamespaces[0] "${PROJECT_NAME}"

echo
echo ">>>>$(print_timestamp) Add OperatorGroup"
oc apply -f data/operator/operatorgroup.yaml

echo
echo ">>>>$(print_timestamp) Update Subscription"
yq w -i data/operator/subscription.yaml spec.channel "${OPERATOR_UPDATE_CHANNEL}"

echo
echo ">>>>$(print_timestamp) Add Subscription"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=deployment-installing-enterprise-in-operator-hub
oc apply -f data/operator/subscription.yaml

echo
echo ">>>>$(print_timestamp) Wait for CP4BA Operator Deployment to be Available"
wait_for_k8s_resource_condition deployment/ibm-cp4a-operator Available

echo
echo ">>>>$(print_timestamp) Wait for ICP4ACluster CRD to be Established"
wait_for_k8s_resource_condition CustomResourceDefinition/icp4aclusters.icp4a.ibm.com Established

echo
echo ">>>>$(print_timestamp) Download and copy DB2 JDBC driver and license to Operator"
oc cp db2/c-db2ucluster-db2u-0:/opt/ibm/db2/V11.5.0.0/java/db2jcc_license_cu.jar ./jdbc/db2/db2jcc_license_cu.jar -c db2u
# DB2 driver JAR download on pupose. oc cp not usd as it caused EOF errors for larger file
curl -k https://repo1.maven.org/maven2/com/ibm/db2/jcc/11.5.6.0/jcc-11.5.6.0.jar -o ./jdbc/db2/db2jcc4.jar
exit_test $? "Download DB2 drivers Failed"
OPERATOR_POD=`oc get pod -o name | grep cp4a | cut -d "/" -f 2`
oc cp ./jdbc ${OPERATOR_POD}:/opt/ansible/share/jdbc

echo
echo ">>>>$(print_timestamp) Prepare custom IAF TLS secret"
oc create secret generic external-tls-secret --from-file=cert.crt=../global-ca/wildcard.crt \
--from-file=cert.key=../global-ca/wildcard.key --from-file=ca.crt=../global-ca/global-ca.crt

echo
echo ">>>>$(print_timestamp) Update AutomationUiConfig CR"
yq w -i data/iaf/automationuiconfig.yaml spec.storage.class "${STORAGE_CLASS_NAME}"

echo
echo ">>>>$(print_timestamp) Wait for AutomationUiConfig CRD to be Established"
wait_for_k8s_resource_condition CustomResourceDefinition/automationuiconfigs.core.automation.ibm.com Established

echo
echo ">>>>$(print_timestamp) Wait for IAF Operators Deployment to be Available"
wait_for_k8s_resource_condition deployment/iaf-core-operator-controller-manager Available
wait_for_k8s_resource_condition deployment/iaf-operator-controller-manager Available

echo
echo ">>>>$(print_timestamp) Add AutomationUiConfig instance"
oc apply -f data/iaf/automationuiconfig.yaml

echo
echo ">>>>$(print_timestamp) Wait for AutomationUiConfig instance Ready state"
wait_for_k8s_resource_condition AutomationUiConfig/iaf-system Ready

echo
echo ">>>>$(print_timestamp) Create root CA certificate Secret"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=certificates-providing-root-ca-certificate
oc create secret tls cp4ba-root-ca --key=../global-ca/global-ca.key --cert=../global-ca/global-ca.crt

echo
echo ">>>>$(print_timestamp) Create wildcard certificate Secret"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=certificates-providing-external-routes
oc create secret tls cp4ba-wildcard --cert ../global-ca/wildcard.crt --key ../global-ca/wildcard.key
# TODO needed the same for ADP CDS pod with different name, report bug, wait for fix. roles\common\tasks\fncm\fncm-ext-tls-certification.yml doesnt ganarate this secret, CDS deployment counts on it exist. temporarily resolved by omitting external_tls_certificate_secret from main cr.yaml
# oc create secret tls cp4ba-fncm-ext-tls-secret --cert ../global-ca/wildcard.crt --key ../global-ca/wildcard.key

echo
echo ">>>>$(print_timestamp) Create LDAP bind Secret"
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" data/shared/secret.yaml
oc apply -f data/shared/secret.yaml

echo
echo ">>>>$(print_timestamp) Resource Registry (RR) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=engine-creating-secrets-protect-sensitive-configuration-data
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=studio-creating-secrets-protect-sensitive-configuration-data

echo
echo ">>>>$(print_timestamp) RR security"
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" data/rr/secret.yaml
oc apply -f data/rr/secret.yaml

echo
echo ">>>>$(print_timestamp) User Management Services (UMS) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-preparing-install-user-management-services

echo
echo ">>>>$(print_timestamp) UMS Security"
# Based on Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=services-creating-ums-secrets
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" data/ums/secret.yaml
oc apply -f data/ums/secret.yaml

echo
echo ">>>>$(print_timestamp) Business Automation Navigator (BAN) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-preparing-install-business-automation-navigator

echo
echo ">>>>$(print_timestamp) BAN Security"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=piban-creating-secrets-protect-sensitive-business-automation-navigator-configuration-data
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" data/ban/secret.yaml
oc apply -f data/ban/secret.yaml

echo
echo ">>>>$(print_timestamp) Business Automation Studio (BAS) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-preparing-install-business-automation-studio

echo
echo ">>>>$(print_timestamp) BAS Security"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=studio-creating-secrets-protect-sensitive-configuration-data
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" data/bas/secret.yaml
oc apply -f data/bas/secret.yaml

echo
echo ">>>>$(print_timestamp) Setup IAF AutomationBase for BAI, PFS"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=insights-customizing-kafka-elasticsearch-server-configuration
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
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" data/iaf/es-secret.yaml
oc apply -f data/iaf/es-secret.yaml

echo
echo ">>>>$(print_timestamp) Update AutomationBase instance"
yq w -i data/iaf/automationbase.yaml spec.elasticsearch.nodegroupspecs[0].storage.class "${STORAGE_CLASS_NAME}"
yq w -i data/iaf/automationbase.yaml spec.kafka.kafka.storage.class "${STORAGE_CLASS_NAME}"
yq w -i data/iaf/automationbase.yaml spec.kafka.zookeeper.storage.class "${STORAGE_CLASS_NAME}"

echo
echo ">>>>$(print_timestamp) Add AutomationBase instance"
oc apply -f data/iaf/automationbase.yaml

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
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" data/iaf/kafkauser-secret.yaml
oc apply -f data/iaf/kafkauser-secret.yaml

echo
echo ">>>>$(print_timestamp) Add new KafkaUser instance"
# Based on https://www.ibm.com/docs/en/cloud-paks/1.0?topic=foundation-administration-guide#day-2-operations-for-kafka reference for Strimzi in Kafka Day 2
oc apply -f data/iaf/kafkauser.yaml

echo
echo ">>>>$(print_timestamp) Wait for KafkaUser instance Ready state"
wait_for_k8s_resource_condition KafkaUser/cpadmin Ready

echo
echo ">>>>$(print_timestamp) Business Automation Insights (BAI) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-preparing-install-business-automation-insights

echo
echo ">>>>$(print_timestamp) Setup Stub Workforce Insights Secret"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-custom-secrets#custom-bpc-workforce-secret   

touch data/bai/workforce-insights-configuration.yaml
oc create secret generic custom-bpc-workforce-secret --from-file=workforce-insights-configuration.yml=data/bai/workforce-insights-configuration.yaml

echo
echo ">>>>$(print_timestamp) BAI custom Secret"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=secrets-creating-custom-bai-secret
# TODO enable when fixed - double encoding in roles\BAI\templates\config\bai-secret-internal.yaml@28
#oc create secret generic custom-bai-secret \
#--from-literal=kibana-username=elasticsearch-admin \
#--from-literal=kibana-password=${UNIVERSAL_PASSWORD} \
#--from-literal=management-username=cpadmin \
#--from-literal=management-password=${UNIVERSAL_PASSWORD}

echo
echo ">>>>$(print_timestamp) Operational Decision Manager (ODM) (decisions pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-preparing-install-operational-decision-manager

echo
echo ">>>>$(print_timestamp) ODM Security DB"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-preparing-install-operational-decision-manager
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" data/odm/secret.yaml
oc apply -f data/odm/secret.yaml

echo
echo ">>>>$(print_timestamp) ODM Security TLS"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-preparing-install-operational-decision-manager
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

echo
echo ">>>>$(print_timestamp) ODM Security UMS OIDC"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=access-configuring-user-ums  
# Adds cpadmin user to all roles and cpadmins to all groups.
oc create secret generic odm-web-security-secret --from-file=webSecurity.xml=data/odm/webSecurity.xml --type=Opaque

echo
echo ">>>>$(print_timestamp) Automation Decision Services (ADS) (decisions_ads pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-preparing-install-automation-decision-services

echo
echo ">>>>$(print_timestamp) ADS Security"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=services-configuring-decision-runtime
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" data/ads/secret.yaml
oc apply -f data/ads/secret.yaml

echo
echo ">>>>$(print_timestamp) FileNet Content Manager (FNCM) (content pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-preparing-install-filenet-content-manager


if [[ $EXTERNAL_SHARE_GOOGLE == "true" ]]; then
echo
echo ">>>>$(print_timestamp) FNCM ES Google API Secret"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=manager-configuring-identity-provider-connection point 4.  
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
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=pifcm-creating-secrets-protect-sensitive-filenet-content-manager-configuration-data
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" data/fncm/secret.yaml
oc apply -f data/fncm/secret.yaml

echo
echo ">>>>$(print_timestamp) Automation Application Engine (AAE) (application pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=pc-preparing-install-business-automation-workflow-runtime-workstream-services

echo
echo ">>>>$(print_timestamp) AAE Security"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=engine-creating-secrets-protect-sensitive-configuration-data
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" data/aae/secret.yaml
oc apply -f data/aae/secret.yaml

# If you plan to use AAE data persistence, you need to update FNCM secret for new object store. 
# Make sure FNCM secret already exists
oc patch secret ibm-fncm-secret -p '{"data": {"aeosDBUsername": "'$(echo -n aeos | base64)'","aeosDBPassword": "'$(echo -n ${UNIVERSAL_PASSWORD} | base64)'"}}'

echo
echo ">>>>$(print_timestamp) Automation Document Processing (ADP) (document_processing pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-preparing-install-automation-document-processing

echo
echo ">>>>$(print_timestamp) ADP Security"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=piadp-creating-secrets-protect-sensitive-document-processing-configuration-data
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" data/adp/secret.yaml
oc apply -f data/adp/secret.yaml
# Update FNCM secret
oc patch secret ibm-fncm-secret -p '{"data": {"devos1DBUsername": "'$(echo -n devos1 | base64)'","devos1DBPassword": "'$(echo -n ${UNIVERSAL_PASSWORD} | base64)'"}}'

echo
echo ">>>>$(print_timestamp) Business Automation Workflow Authoring (BAWAUT)"

echo
echo ">>>>$(print_timestamp) BAWAUT Security"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=authoring-creating-secrets-protect-sensitive-configuration-data
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" data/bawaut/secret.yaml
oc apply -f data/bawaut/secret.yaml
# Update FNCM secret
oc patch secret ibm-fncm-secret -p '{"data": {"badocsDBUsername": "'$(echo -n badocs | base64)'","badocsDBPassword": "'$(echo -n ${UNIVERSAL_PASSWORD} | base64)'"}}'
oc patch secret ibm-fncm-secret -p '{"data": {"batosDBUsername": "'$(echo -n batos | base64)'","batosDBPassword": "'$(echo -n ${UNIVERSAL_PASSWORD} | base64)'"}}'
oc patch secret ibm-fncm-secret -p '{"data": {"badosDBUsername": "'$(echo -n bados | base64)'","badosDBPassword": "'$(echo -n ${UNIVERSAL_PASSWORD} | base64)'"}}'

echo
echo ">>>>$(print_timestamp) CP4BA predeploy install completed"