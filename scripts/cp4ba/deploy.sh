#!/bin/bash

# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=deployment-installing-enterprise-script

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
echo ">>>>$(print_timestamp) CP4BA deploy install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Switch Project"
oc project ${PROJECT_NAME}

echo
echo ">>>>$(print_timestamp) Make helper scripts executable"
chmod u+x data/add-pattern.sh
chmod u+x data/add-component.sh

echo
echo ">>>>$(print_timestamp) Update Base CR"
yq w -i data/cr.yaml metadata.name "${CR_META_NAME}"
yq w -i data/cr.yaml metadata.labels.release "${CP4BA_VERSION}"
yq w -i data/cr.yaml spec.appVersion "${CP4BA_VERSION}"
yq w -i data/cr.yaml spec.shared_configuration.sc_deployment_hostname_suffix "{{ meta.namespace }}.${OCP_APPS_ENDPOINT}"
yq w -i data/cr.yaml spec.shared_configuration.storage_configuration.sc_slow_file_storage_classname "${STORAGE_CLASS_NAME}"
yq w -i data/cr.yaml spec.shared_configuration.storage_configuration.sc_medium_file_storage_classname "${STORAGE_CLASS_NAME}"
yq w -i data/cr.yaml spec.shared_configuration.storage_configuration.sc_fast_file_storage_classname "${STORAGE_CLASS_NAME}"
yq w -i data/cr.yaml spec.shared_configuration.sc_deployment_platform "${DEPLOYMENT_PLATFORM}"
yq w -i data/cr.yaml spec.ldap_configuration.lc_ldap_server "${LDAP_HOSTNAME}"

echo
echo ">>>>$(print_timestamp) Resource Registry (RR) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-checking-cluster-configuration point 3
./data/add-pattern.sh data/cr.yaml "foundation"
yq m -i -x -a append data/cr.yaml data/rr/cr.yaml

echo
echo ">>>>$(print_timestamp) User Management Services (UMS) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-user-management-services

echo
echo ">>>>$(print_timestamp) Update UMS CR"
yq w -i data/ums/cr.yaml spec.datasource_configuration.dc_ums_datasource.dc_ums_oauth_host "${DB2_HOSTNAME}"
yq w -i data/ums/cr.yaml spec.datasource_configuration.dc_ums_datasource.dc_ums_teamserver_host "${DB2_HOSTNAME}"

echo
echo ">>>>$(print_timestamp) Add UMS to CR"
./data/add-pattern.sh data/cr.yaml "foundation"
./data/add-component.sh data/cr.yaml "ums"
yq m -i -x -a append data/cr.yaml data/ums/cr.yaml

echo
echo ">>>>$(print_timestamp) Business Automation Navigator (BAN) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-business-automation-navigator

echo
echo ">>>>$(print_timestamp) Update BAN CR"
yq w -i data/ban/cr.yaml spec.datasource_configuration.dc_icn_datasource.database_servername "${DB2_HOSTNAME}"
yq w -i data/ban/cr.yaml spec.navigator_configuration.java_mail.host "${MAIL_HOSTNAME}"

echo
echo ">>>>$(print_timestamp) Add BAN to CR"
./data/add-pattern.sh data/cr.yaml "foundation"
yq m -i -x -a append data/cr.yaml data/ban/cr.yaml

if [[ $EXTERNAL_SHARE_GOOGLE == "true" ]]; then
  echo 
  echo ">>>>$(print_timestamp) Add BAN Google IDP configuration"
  yq w -i data/cr.yaml spec.navigator_configuration.icn_production_setting.jvm_customize_options \
  "DELIM=;-Dcom.filenet.authentication.ExShareGID.AuthTokenOrder=oidc,oauth,ltpa"
fi

echo
echo ">>>>$(print_timestamp) Business Automation Studio (BAS) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-business-automation-studio

echo
echo ">>>>$(print_timestamp) Update BAS CR"
yq w -i data/bas/cr.yaml spec.bastudio_configuration.database.host "${DB2_HOSTNAME}"
yq w -i data/bas/cr.yaml spec.bastudio_configuration.playback_server.database.host "${DB2_HOSTNAME}"

echo
echo ">>>>$(print_timestamp) Add BAS to CR"
./data/add-pattern.sh data/cr.yaml "foundation"
./data/add-component.sh data/cr.yaml "bas"
yq m -i -x -a append data/cr.yaml data/bas/cr.yaml

echo
echo ">>>>$(print_timestamp) Business Automation Insights (BAI) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-business-automation-insights

echo
echo ">>>>$(print_timestamp) Add BAI to CR"
./data/add-pattern.sh data/cr.yaml "foundation"
./data/add-component.sh data/cr.yaml "bai"
yq m -i -x -a append data/cr.yaml data/bai/cr.yaml

echo
echo ">>>>$(print_timestamp) Operational Decision Manager (ODM) (decisions pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-operational-decision-manager

echo
echo ">>>>$(print_timestamp) Update ODM CR"
yq w -i data/odm/cr.yaml spec.datasource_configuration.dc_odm_datasource.database_servername "${DB2_HOSTNAME}"

echo
echo ">>>>$(print_timestamp) Add ODM to CR"
./data/add-pattern.sh data/cr.yaml "decisions"
./data/add-component.sh data/cr.yaml "decisionCenter"
./data/add-component.sh data/cr.yaml "decisionRunner"
./data/add-component.sh data/cr.yaml "decisionServerRuntime"
yq m -i -x -a append data/cr.yaml data/odm/cr.yaml

echo
echo ">>>>$(print_timestamp) Automation Decision Services (ADS) (decisions_ads pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-automation-decision-services

echo
echo ">>>>$(print_timestamp) Add ADS to CR"
./data/add-pattern.sh data/cr.yaml "decisions_ads"
./data/add-component.sh data/cr.yaml "ads_designer"
./data/add-component.sh data/cr.yaml "ads_runtime"
yq m -i -x -a append data/cr.yaml data/ads/cr.yaml

echo
echo ">>>>$(print_timestamp) FileNet Content Manager (FNCM) (content pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-filenet-content-manager

echo
echo ">>>>$(print_timestamp) Update FNCM CR"
yq w -i data/fncm/cr-cpe.yaml spec.datasource_configuration.dc_gcd_datasource.database_servername "${DB2_HOSTNAME}"
yq w -i data/fncm/cr-cpe.yaml spec.datasource_configuration.dc_os_datasources[0].database_servername "${DB2_HOSTNAME}"

echo
echo ">>>>$(print_timestamp) Add FNCM to CR"
./data/add-pattern.sh data/cr.yaml "content"
yq m -i -x -a append data/cr.yaml data/fncm/cr-cpe.yaml
yq m -i -x -a append data/cr.yaml data/fncm/cr-graphql.yaml
./data/add-component.sh data/cr.yaml "cmis"
yq m -i -x -a append data/cr.yaml data/fncm/cr-cmis.yaml
./data/add-component.sh data/cr.yaml "css"
yq m -i -x -a append data/cr.yaml data/fncm/cr-css.yaml
./data/add-component.sh data/cr.yaml "es"
yq m -i -x -a append data/cr.yaml data/fncm/cr-es.yaml
./data/add-component.sh data/cr.yaml "tm"
yq m -i -x -a append data/cr.yaml data/fncm/cr-tm.yaml

if [[ $EXTERNAL_SHARE_GOOGLE == "true" ]]; then
  echo
  echo ">>>>$(print_timestamp) Add Google TLS and IDP configuration to CR"
  yq w -i data/cr.yaml spec.shared_configuration.trusted_certificate_list[+] "google-tls"
  yq m -i -x -a append data/cr.yaml data/fncm/cr-es-gid.yaml
fi

echo
echo ">>>>$(print_timestamp) Automation Application Engine (AAE) (application pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-business-automation-application

echo
echo ">>>>$(print_timestamp) Update AAE CR"
yq w -i data/aae/cr.yaml spec.application_engine_configuration[0].database.host "${DB2_HOSTNAME}"
yq w -i data/aae/cr-persistence.yaml spec.datasource_configuration.dc_os_datasources[0].database_servername "${DB2_HOSTNAME}"

echo
echo ">>>>$(print_timestamp) Add AAE to CR"
./data/add-pattern.sh data/cr.yaml "application"
./data/add-component.sh data/cr.yaml "app_designer"
./data/add-component.sh data/cr.yaml "ae_data_persistence"
yq m -i -x -a append data/cr.yaml data/aae/cr.yaml
yq m -i -x -a append data/cr.yaml data/aae/cr-persistence.yaml
yq w -i data/cr.yaml spec.application_engine_configuration[0].data_persistence.enable "true"

echo
echo ">>>>$(print_timestamp) Automation Document Processing (ADP) (document_processing pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-document-processing

echo
echo ">>>>$(print_timestamp) Update ADP CR"
yq w -i data/adp/cr.yaml spec.datasource_configuration.dc_ca_datasource.database_servername "${DB2_HOSTNAME}"
yq w -i data/adp/cr.yaml spec.datasource_configuration.dc_os_datasources[0].database_servername "${DB2_HOSTNAME}"

echo
echo ">>>>$(print_timestamp) Add ADP to CR"
./data/add-pattern.sh data/cr.yaml "document_processing"
./data/add-component.sh data/cr.yaml "document_processing_designer"
yq m -i -x -a append data/cr.yaml data/adp/cr.yaml

echo
echo ">>>>$(print_timestamp) Business Automation Workflow Authoring (BAWAUT)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=resource-configuring-business-automation-workflow-authoring

echo
echo ">>>>$(print_timestamp) Update BAWUAT CR"
yq w -i data/bawaut/cr.yaml spec.datasource_configuration.dc_os_datasources[0].database_servername "${DB2_HOSTNAME}"
yq w -i data/bawaut/cr.yaml spec.datasource_configuration.dc_os_datasources[1].database_servername "${DB2_HOSTNAME}"
yq w -i data/bawaut/cr.yaml spec.datasource_configuration.dc_os_datasources[2].database_servername "${DB2_HOSTNAME}"
yq w -i data/bawaut/cr.yaml spec.workflow_authoring_configuration.database.server_name "${DB2_HOSTNAME}"

echo
echo ">>>>$(print_timestamp) Add BAWAUT to CR"
./data/add-pattern.sh data/cr.yaml "workflow"
./data/add-component.sh data/cr.yaml "baw_authoring"
yq m -i -x -a append data/cr.yaml data/bawaut/cr.yaml

echo
echo ">>>>$(print_timestamp) Apply completed CR"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=script-deploying-custom-resource
oc apply -f data/cr.yaml

echo
echo ">>>>$(print_timestamp) Wait for CP4BA deployment to complete, this will take hours"
#wait_for_cp4ba ${CR_META_NAME} ${CP4BA_ATTEMPTS} ${CP4BA_DELAY}

echo
echo ">>>>$(print_timestamp) Wait for Zen instance Ready state"
wait_for_k8s_resource_condition Cartridge/icp4ba Ready ${DEFAULT_ATTEMPTS_4} ${DEFAULT_DELAY_4}
echo
echo ">>>>$(print_timestamp) Wait for UMS Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-ums-deployment Available ${DEFAULT_ATTEMPTS_4} ${DEFAULT_DELAY_4}
echo
echo ">>>>$(print_timestamp) Wait for BAS PB Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-pbk-ae-deployment Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for BAS JMS StatefulSet Ready state"
wait_for_k8s_resource_condition_generic StatefulSet/${CR_META_NAME}-bastudio-authoring-jms ".status.readyReplicas" 1 ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for BAS Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-bastudio-deployment Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for FNCM CPE Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-cpe-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for FNCM CSS Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-css-deploy-1 Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for FNCM CMIS Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-cmis-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for FNCM GraphQL Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-graphql-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for FNCM ES Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-es-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for FNCM TM Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-tm-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ADP Mongo Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-mongo-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ADP Git Gateway Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-gitgateway-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ADP CDRA Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-cdra-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ADP Viewone Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-viewone-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ADP CPDS Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-cpds-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ADP CDS Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-cds-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for BAN Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-navigator-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ADP Redis StatefulSet Ready state"
wait_for_k8s_resource_condition_generic StatefulSet/${CR_META_NAME}-redis-ha-server ".status.readyReplicas" 3 ${DEFAULT_ATTEMPTS_4} ${DEFAULT_DELAY_4}
echo
echo ">>>>$(print_timestamp) Wait for ADP RabbitMQ StatefulSet Ready state"
wait_for_k8s_resource_condition_generic StatefulSet/${CR_META_NAME}-rabbitmq-ha ".status.readyReplicas" 2 ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ADP NL extractor Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-natural-language-extractor Available ${DEFAULT_ATTEMPTS_4} ${DEFAULT_DELAY_4}
echo
echo ">>>>$(print_timestamp) Wait for ADP NL extractor Pod Ready state (Not waiting for each individual ADP CA pod)"
echo ">>>>$(print_timestamp) ADP CA pods take long time to pull images on first deployment"
# Also waiting on pod because Deployment becomes available even when the pod is not ready due to extra long image pulling time
nl_extract_pod=`oc get pod -o name | grep natural-language-extractor | head -n 1`
wait_for_k8s_resource_condition ${nl_extract_pod} Ready ${DEFAULT_ATTEMPTS_4} ${DEFAULT_DELAY_4}
echo
echo ">>>>$(print_timestamp) Wait for BAI Management Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-bai-management Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for BAI BPC Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-bai-business-performance-center Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for MLS ITP Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-mls-itp Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for MLS WFI Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-mls-wfi Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ODM DC Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-odm-decisioncenter Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ODM DS Runtime Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-odm-decisionserverruntime Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ODM DS Console Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-odm-decisionserverconsole Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ODM Decision Runner Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-odm-decisionrunner Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for AAE Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-instance1-aae-ae-deployment Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for PFS StatefulSet Ready state"
wait_for_k8s_resource_condition_generic StatefulSet/${CR_META_NAME}-pfs ".status.readyReplicas" 2 ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for BAWAUT StatefulSet Ready state"
wait_for_k8s_resource_condition_generic StatefulSet/${CR_META_NAME}-workflow-authoring-baw-server ".status.readyReplicas" 1 ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
echo
echo ">>>>$(print_timestamp) Wait for ADS runtime service Deployment Available state (Not waiting for each individual ADS pod)"
wait_for_k8s_resource_condition Deployment/${CR_META_NAME}-ads-runtime-service Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

wait_for_cp4ba ${CR_META_NAME} ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) CP4BA deploy install completed"
