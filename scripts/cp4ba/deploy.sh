#!/bin/bash

# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=deployment-checking-completing-your-custom-resource
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=deployment-deploying-custom-resource-you-created-script

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
echo ">>>>$(print_timestamp) CP4BA deploy install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Switch Project"
oc project ${CP4BA_PROJECT_NAME}

echo
echo ">>>>$(print_timestamp) Make helper scripts executable"
chmod u+x data/add-pattern.sh
chmod u+x data/add-component.sh

echo
echo ">>>>$(print_timestamp) Update Base CR"
sed -f - data/cr.yaml > data/cr.target.yaml << SED_SCRIPT
s|{{CP4BA_CR_META_NAME}}|${CP4BA_CR_META_NAME}|g
s|{{CP4BA_VERSION}}|${CP4BA_VERSION}|g
s|{{OCP_APPS_ENDPOINT}}|${OCP_APPS_ENDPOINT}|g
s|{{STORAGE_CLASS_NAME}}|${STORAGE_CLASS_NAME}|g
s|{{DEPLOYMENT_PLATFORM}}|${DEPLOYMENT_PLATFORM}|g
s|{{LDAP_HOSTNAME}}|${LDAP_HOSTNAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Resource Registry (RR) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=resource-checking-cluster-configuration point 3
./data/add-pattern.sh data/cr.target.yaml "foundation"
yq m -i -x -a append data/cr.target.yaml data/rr/cr.yaml

echo
echo ">>>>$(print_timestamp) Business Automation Navigator (BAN) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=resource-configuring-business-automation-navigator

echo
echo ">>>>$(print_timestamp) Update BAN CR"
sed -f - data/ban/cr.yaml > data/ban/cr.target.yaml << SED_SCRIPT
s|{{DB2_HOSTNAME}}|${DB2_HOSTNAME}|g
s|{{MAIL_HOSTNAME}}|${MAIL_HOSTNAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add BAN to CR"
./data/add-pattern.sh data/cr.target.yaml "foundation"
yq m -i -x -a append data/cr.target.yaml data/ban/cr.target.yaml

if [[ $EXTERNAL_SHARE_GOOGLE == "true" ]]; then
  echo 
  echo ">>>>$(print_timestamp) Add BAN Google IDP configuration"
  yq w -i data/cr.target.yaml spec.navigator_configuration.icn_production_setting.jvm_customize_options \
  "DELIM=;-Dcom.filenet.authentication.ExShareGID.AuthTokenOrder=oidc,oauth,ltpa"
fi

echo
echo ">>>>$(print_timestamp) Business Automation Studio (BAS) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=resource-configuring-business-automation-studio

echo
echo ">>>>$(print_timestamp) Update BAS CR"
sed -f - data/bas/cr.yaml > data/bas/cr.target.yaml << SED_SCRIPT
s|{{DB2_HOSTNAME}}|${DB2_HOSTNAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add BAS to CR"
./data/add-pattern.sh data/cr.target.yaml "foundation"
./data/add-component.sh data/cr.target.yaml "bas"
yq m -i -x -a append data/cr.target.yaml data/bas/cr.target.yaml

echo
echo ">>>>$(print_timestamp) Business Automation Insights (BAI) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=resource-configuring-business-automation-insights

echo
echo ">>>>$(print_timestamp) Add BAI to CR"
./data/add-pattern.sh data/cr.target.yaml "foundation"
./data/add-component.sh data/cr.target.yaml "bai"
yq m -i -x -a append data/cr.target.yaml data/bai/cr.yaml

echo
echo ">>>>$(print_timestamp) Operational Decision Manager (ODM) (decisions pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=resource-configuring-operational-decision-manager

echo
echo ">>>>$(print_timestamp) Update ODM CR"
sed -f - data/odm/cr.yaml > data/odm/cr.target.yaml << SED_SCRIPT
s|{{DB2_HOSTNAME}}|${DB2_HOSTNAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add ODM to CR"
./data/add-pattern.sh data/cr.target.yaml "decisions"
./data/add-component.sh data/cr.target.yaml "decisionCenter"
./data/add-component.sh data/cr.target.yaml "decisionRunner"
./data/add-component.sh data/cr.target.yaml "decisionServerRuntime"
yq m -i -x -a append data/cr.target.yaml data/odm/cr.target.yaml

echo
echo ">>>>$(print_timestamp) Automation Decision Services (ADS) (decisions_ads pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=resource-configuring-automation-decision-services

echo
echo ">>>>$(print_timestamp) Add ADS to CR"
./data/add-pattern.sh data/cr.target.yaml "decisions_ads"
./data/add-component.sh data/cr.target.yaml "ads_designer"
./data/add-component.sh data/cr.target.yaml "ads_runtime"
yq m -i -x -a append data/cr.target.yaml data/ads/cr.yaml

echo
echo ">>>>$(print_timestamp) FileNet Content Manager (FNCM) (content pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=resource-configuring-filenet-content-manager

echo
echo ">>>>$(print_timestamp) Update FNCM CR"
sed -f - data/fncm/cr-cpe.yaml > data/fncm/cr-cpe.target.yaml << SED_SCRIPT
s|{{DB2_HOSTNAME}}|${DB2_HOSTNAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add FNCM to CR"
./data/add-pattern.sh data/cr.target.yaml "content"
yq m -i -x -a append data/cr.target.yaml data/fncm/cr-cpe.target.yaml
yq m -i -x -a append data/cr.target.yaml data/fncm/cr-graphql.yaml
./data/add-component.sh data/cr.target.yaml "cmis"
yq m -i -x -a append data/cr.target.yaml data/fncm/cr-cmis.yaml
./data/add-component.sh data/cr.target.yaml "css"
yq m -i -x -a append data/cr.target.yaml data/fncm/cr-css.yaml
./data/add-component.sh data/cr.target.yaml "es"
yq m -i -x -a append data/cr.target.yaml data/fncm/cr-es.yaml
./data/add-component.sh data/cr.target.yaml "tm"
yq m -i -x -a append data/cr.target.yaml data/fncm/cr-tm.yaml

if [[ $EXTERNAL_SHARE_GOOGLE == "true" ]]; then
  echo
  echo ">>>>$(print_timestamp) Add Google TLS and IDP configuration to CR"
  yq w -i data/cr.target.yaml spec.shared_configuration.trusted_certificate_list[+] "google-tls"
  yq m -i -x -a append data/cr.target.yaml data/fncm/cr-es-gid.yaml
fi

echo
echo ">>>>$(print_timestamp) Automation Application Engine (AAE) (application pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=resource-configuring-business-automation-application

echo
echo ">>>>$(print_timestamp) Update AAE CR"
sed -f - data/aae/cr.yaml > data/aae/cr.target.yaml << SED_SCRIPT
s|{{DB2_HOSTNAME}}|${DB2_HOSTNAME}|g
SED_SCRIPT
sed -f - data/aae/cr-persistence.yaml > data/aae/cr-persistence.target.yaml << SED_SCRIPT
s|{{DB2_HOSTNAME}}|${DB2_HOSTNAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add AAE to CR"
./data/add-pattern.sh data/cr.target.yaml "application"
./data/add-component.sh data/cr.target.yaml "app_designer"
./data/add-component.sh data/cr.target.yaml "ae_data_persistence"
yq m -i -x -a append data/cr.target.yaml data/aae/cr.target.yaml
yq m -i -x -a append data/cr.target.yaml data/aae/cr-persistence.target.yaml
yq w -i data/cr.target.yaml spec.application_engine_configuration[0].data_persistence.enable "true"

echo
echo ">>>>$(print_timestamp) Automation Document Processing (ADP) (document_processing pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=resource-configuring-document-processing

echo
echo ">>>>$(print_timestamp) Update ADP CR"
sed -f - data/adp/cr.yaml > data/adp/cr.target.yaml << SED_SCRIPT
s|{{DB2_HOSTNAME}}|${DB2_HOSTNAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add ADP to CR"
./data/add-pattern.sh data/cr.target.yaml "document_processing"
./data/add-component.sh data/cr.target.yaml "document_processing_designer"
yq m -i -x -a append data/cr.target.yaml data/adp/cr.target.yaml

echo
echo ">>>>$(print_timestamp) Business Automation Workflow Authoring (BAWAUT)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=resource-configuring-business-automation-workflow-authoring

echo
echo ">>>>$(print_timestamp) Update BAWUAT CR"
sed -f - data/bawaut/cr.yaml > data/bawaut/cr.target.yaml << SED_SCRIPT
s|{{DB2_HOSTNAME}}|${DB2_HOSTNAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add BAWAUT to CR"
./data/add-pattern.sh data/cr.target.yaml "workflow"
./data/add-component.sh data/cr.target.yaml "baw_authoring"
yq m -i -x -a append data/cr.target.yaml data/bawaut/cr.target.yaml

echo
echo ">>>>$(print_timestamp) Apply completed CR"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=deployment-deploying-custom-resource-you-created-script
oc apply -f data/cr.target.yaml

echo
echo ">>>>$(print_timestamp) Wait for CP4BA deployment to complete, this will take hours"

echo
echo ">>>>$(print_timestamp) Switch to Project ibm-common-services"
oc project ibm-common-services

echo
echo ">>>>$(print_timestamp) Manually approve Zen Subscription"
manage_manual_operator ibm-zen-operator ibm-zen-operator

echo
echo ">>>>$(print_timestamp) Switch back to CP4BA Project"
oc project ${CP4BA_PROJECT_NAME}

echo
echo ">>>>$(print_timestamp) Wait for Zen instance Ready state"
wait_for_k8s_resource_condition Cartridge/icp4ba Ready ${DEFAULT_ATTEMPTS_4} ${DEFAULT_DELAY_4}

echo
echo ">>>>$(print_timestamp) Wait for Prereqs Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.prereq.iafStatus' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.prereq.iamIntegrationStatus' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.prereq.rootCAStatus' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for one RR to Ready state"
wait_for_k8s_resource_appear_partial_unique pod ${CP4BA_CR_META_NAME}-dba-rr ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition `oc get pod -o name | grep ${CP4BA_CR_META_NAME}-dba-rr | head -n 1` Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Approve Operators for BTS"

echo
echo ">>>>$(print_timestamp) Switch to Project ibm-common-services"
oc project ibm-common-services

manage_manual_operator ibm-bts-operator ibm-bts-operator-controller-manager

echo
echo ">>>>$(print_timestamp) Wait for Postgresql InstallPlan to be created"
wait_for_k8s_resource_condition_generic Subscription/cloud-native-postgresql ".status.installplan.kind" InstallPlan ${DEFAULT_ATTEMPTS_1} ${DEFAULT_DELAY_1}

echo
echo ">>>>$(print_timestamp) Approve Postgresql InstallPlan"
install_plan=`oc get subscription cloud-native-postgresql -o json | jq -r '.status.installplan.name'`
oc patch installplan ${install_plan} --type merge --patch '{"spec":{"approved":true}}'

echo
echo ">>>>$(print_timestamp) Switch back to CP4BA Project"
oc project ${CP4BA_PROJECT_NAME}

#TODO hotfix remove when BTS pull secrets fixed START
echo
echo ">>>>$(print_timestamp) Wait for BTS SA to be created"
wait_for_k8s_resource_appear ServiceAccount/ibm-bts-cnpg-${CP4BA_PROJECT_NAME}-${CP4BA_CR_META_NAME}-bts ${DEFAULT_ATTEMPTS} ${DEFAULT_DELAY}
echo
echo ">>>>$(print_timestamp) Patch BTS SA to mitigate pull secret issue"
oc get sa ibm-bts-cnpg-${CP4BA_PROJECT_NAME}-${CP4BA_CR_META_NAME}-bts -o json | jq '.imagePullSecrets += [ {name: "ibm-entitlement-key"} ]' | oc apply -f -

resolve_bts () {
  local attempts=${DEFAULT_ATTEMPTS}
  local delay=${DEFAULT_DELAY}
  
  local attempt=0
  echo "Resolving BTS with '${attempts}' attempts with '${delay}' seconds delay each (total of `expr ${attempts} \* ${delay} / 60` minutes)." 
  while : ; do
    echo "Attempt #`expr ${attempt} + 1`/${attempts}: " 

    oc get pod/ibm-bts-cnpg-${CP4BA_PROJECT_NAME}-${CP4BA_CR_META_NAME}-bts-1 && echo "Success - BTS resolved" && break

    pod_name=`oc get pod -o name | grep ibm-bts-cnpg-${CP4BA_PROJECT_NAME}-${CP4BA_CR_META_NAME}-bts-1-initdb`

    if [[ ! -z "$pod_name" ]]
    then
      value=`oc get ${pod_name} -o json | jq -r ".status.containerStatuses[0].state.waiting.reason"`
      if [ "$value" = "ImagePullBackOff" ] || [ "$value" = "ErrImagePull" ]
      then
        oc delete ${pod_name}
        echo "Success - BTS resolved"
        break
      fi
    fi

    attempt=$((attempt+1))
    if ((attempt == attempts)); then
      echo "Failed - BTS could not be resolved, you need to troubleshoot"
      exit 1
    fi
    sleep $delay
  done
}

echo
echo ">>>>$(print_timestamp) Resolve BTS"
resolve_bts

#TODO hotfix remove when BTS pull secrets fixed END

echo
echo ">>>>$(print_timestamp) Wait for BTS Ready state"
wait_for_k8s_resource_condition_generic BusinessTeamsService/cp4ba-bts '.status.serviceStatus' ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo ">>>>$(print_timestamp) Wait for FNCM CPE Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-cpe-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for FNCM CSS Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-css-deploy-1 Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for FNCM CMIS Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-cmis-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for FNCM GraphQL Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-graphql-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for FNCM ES Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-es-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for FNCM TM Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-tm-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADP Mongo Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-mongo-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADP Git Gateway Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-gitgateway-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADP CDRA Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-cdra-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADP Viewone Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-viewone-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADP CPDS Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-cpds-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADP CDS Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-cds-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for BAN Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-navigator-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for BAS PB Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-pbk-ae-deployment Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for BAS StatefulSet Available state"
wait_for_k8s_resource_condition_generic StatefulSet/${CP4BA_CR_META_NAME}-bastudio-deployment ".status.readyReplicas" 2 ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADP Redis StatefulSet Ready state"
wait_for_k8s_resource_condition_generic StatefulSet/${CP4BA_CR_META_NAME}-redis-ha-server ".status.readyReplicas" 2 ${DEFAULT_ATTEMPTS_4} ${DEFAULT_DELAY_4}

echo
echo ">>>>$(print_timestamp) Wait for ADP RabbitMQ StatefulSet Ready state"
wait_for_k8s_resource_condition_generic StatefulSet/${CP4BA_CR_META_NAME}-rabbitmq-ha ".status.readyReplicas" 2 ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADP NL extractor Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-natural-language-extractor Available ${DEFAULT_ATTEMPTS_4} ${DEFAULT_DELAY_4}

echo
echo ">>>>$(print_timestamp) Wait for ADP NL extractor Pod Ready state (Not waiting for each individual ADP CA pod)"
echo ">>>>$(print_timestamp) ADP CA pods take long time to pull images on first deployment"
# Also waiting on pod because Deployment becomes available even when the pod is not ready due to extra long image pulling time
wait_for_k8s_resource_condition `oc get pod -o name | grep natural-language-extractor | head -n 1` Ready ${DEFAULT_ATTEMPTS_4} ${DEFAULT_DELAY_4}

echo
echo ">>>>$(print_timestamp) Wait for BAI Ready state"
wait_for_k8s_resource_condition InsightsEngine/iaf-insights-engine Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for MLS ITP Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-mls-itp Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for MLS WFI Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-mls-wfi Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ODM DC Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-odm-decisioncenter Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ODM DS Runtime Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-odm-decisionserverruntime Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ODM DS Console Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-odm-decisionserverconsole Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ODM Decision Runner Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-odm-decisionrunner Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for AAE Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-instance1-aae-ae-deployment Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for PFS StatefulSet Ready state"
wait_for_k8s_resource_condition_generic StatefulSet/${CP4BA_CR_META_NAME}-pfs ".status.readyReplicas" 2 ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for BAWAUT JMS StatefulSet Ready state"
wait_for_k8s_resource_condition_generic StatefulSet/${CP4BA_CR_META_NAME}-workflow-authoring-baw-jms ".status.readyReplicas" 1 ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for BAWAUT StatefulSet Ready state"
wait_for_k8s_resource_condition_generic StatefulSet/${CP4BA_CR_META_NAME}-workflow-authoring-baw-server ".status.readyReplicas" 2 ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS Run Service Ready states"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-ads-run-service Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS Parsing Service Ready states"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-ads-parsing-service Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS Git Service Ready states"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-ads-git-service Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS Download Service Ready states"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-ads-download-service Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS REST API Ready states"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-ads-rest-api Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS Front Ready states"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-ads-front Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS Build Service Ready states"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-ads-embedded-build-service Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS Credentials Service Ready states"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-ads-credentials-service Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS Runtime Service Ready states"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-ads-runtime-service Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

wait_for_cp4ba ${CP4BA_CR_META_NAME} ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) CP4BA deploy install completed"
