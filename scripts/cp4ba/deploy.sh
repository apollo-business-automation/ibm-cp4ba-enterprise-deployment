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
#wait_for_cp4ba ${CP4BA_CR_META_NAME} ${CP4BA_ATTEMPTS} ${CP4BA_DELAY}

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
echo ">>>>$(print_timestamp) Wait for RR Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components."resource-registry".rrCluster' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components."resource-registry".rrService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

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

echo
echo ">>>>$(print_timestamp) Wait for BTS SA to be created"
wait_for_k8s_resource_appear ServiceAccount/ibm-bts-cnpg-${CP4BA_PROJECT_NAME}-${CP4BA_CR_META_NAME}-bts ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

#TODO hotfix remove when BTS pull secrets fixed
echo
echo ">>>>$(print_timestamp) Patch BTS SA to mitigate pull secret issue"
oc get sa ibm-bts-cnpg-${CP4BA_PROJECT_NAME}-${CP4BA_CR_META_NAME}-bts -o json | jq '.imagePullSecrets += [ {name: "ibm-entitlement-key"} ]' | oc apply -f -
echo
echo ">>>>$(print_timestamp) Rstart BTS job"
pod_name=`oc get pod -o name | grep ibm-bts-cnpg-${CP4BA_PROJECT_NAME}-${CP4BA_CR_META_NAME}-bts`
oc delete $pod_name

echo
echo ">>>>$(print_timestamp) Wait for BTS Ready state"
wait_for_k8s_resource_condition_generic BusinessTeamsService/cp4ba-bts '.status.serviceStatus' ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for FNCM CPE Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.cpe.cpeZenInegration' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.cpe.cpeStorage' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.cpe.cpeJDBCDriver' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.cpe.cpeDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.cpe.cpeService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.cpe.cpeRoute' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for FNCM CSS Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.css.cssStorage' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.css.cssDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.css.cssService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for FNCM CMIS Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.cmis.cmisZenInegration' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.cmis.cmisStorage' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.cmis.cmisDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.cmis.cmisService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.cmis.cmisRoute' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for FNCM GraphQL Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.graphql.graphqlStorage' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.graphql.graphqlDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.graphql.graphqlService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.graphql.graphqlRoute' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for FNCM ES Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.extshare.extshareStorage' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.extshare.extshareDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.extshare.extshareService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.extshare.extshareRoute' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for FNCM TM Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.tm.tmStorage' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.tm.tmDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.tm.tmService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.tm.tmRoute' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADP Mongo Deployment Available state"
wait_for_k8s_resource_condition Deployment/${CP4BA_CR_META_NAME}-mongo-deploy Available ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADP Git Gateway Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.gitgatewayService.gitsvcPersistentVolume' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.gitgatewayService.gitsvcDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.gitgatewayService.gitsvcService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADP CDRA Ready states"
#TODO wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.contentDesignerRepoAPI.cdraPersistentVolume' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.contentDesignerRepoAPI.cdraZenInegration' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
#TODO wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.contentDesignerRepoAPI.cdraDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
#TODO wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.contentDesignerRepoAPI.cdraService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADP Viewone Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.viewone.viewoneStorage' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
#TODO wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.viewone.viewoneRRIntegration' NotInstalled ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
#TODO wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.viewone.basViewoneImportJob' NotInstalled ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.viewone.viewoneDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.viewone.viewoneService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.viewone.viewoneRoute' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADP CPDS Ready states"
#TODO wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.contentProjectDeploymentService.cpdsPersistentVolume' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.contentProjectDeploymentService.cpdsZenInegration' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
#TODO wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.contentProjectDeploymentService.cpdsDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
#TODO wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.contentProjectDeploymentService.cpdsService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADP CDS Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.contentDesignerService.cdsPersistentVolume' NotInstalled ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.contentDesignerService.cdsZenInegration' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.contentDesignerService.cdsDeployment' NotInstalled ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.contentDesignerService.cdsService' NotInstalled ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for BAN Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.navigator.navigatorStorage' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.navigator.navigatorZenInegration' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.navigator.navigatorDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.navigator.navigatorService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for BAS PB Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components."ae-'${CP4BA_CR_META_NAME}'-pbk".service' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for BAS Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.bastudio.service' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADP CA Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.ca.caDatabaseVerification' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.ca.caSecrets' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.ca.caStorageVerification' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.ca.caService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.ca.caZenRegistration' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.ca.caRRRegistration' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.ca.caDeployment' Successful ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for BAI Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.bai.insightsEngine' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.bai.bai_deploy_status' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for BAWAUT BAML Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.baml.bamlDeployStatus' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.baml.bamlServiceStatus' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ODM Ready states"
# Whole deployment created by phases thus the ordering of waits
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.odm.odmDecisionServerConsoleZenIntegration' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.odm.odmDecisionRunnerZenIntegration' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.odm.odmDecisionCenterZenIntegration' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.odm.odmDecisionServerRuntimeZenIntegration' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.odm.odmOIDCRegistrationJob' Successful ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.odm.odmDecisionServerConsoleService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.odm.odmDecisionRunnerService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.odm.odmDecisionCenterService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.odm.odmDecisionServerRuntimeService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.odm.odmDecisionServerConsoleDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.odm.odmDecisionRunnerDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.odm.odmDecisionCenterDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.odm.odmDecisionServerRuntimeDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for AE Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components."ae-'${CP4BA_CR_META_NAME}'-instance1-aae".service' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for BAWAUT PFS Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.pfs.pfsZenIntegration' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.pfs.pfsDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.pfs.pfsService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for BAWAUT Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components."workflow-authoring".service' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS LTPA Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsLtpaCreation.adsLtpaCreationJob' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS Run Service Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsRunService.adsRunServiceDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsRunService.adsRunServiceService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS Parsing Service Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsParsingService.adsParsingServiceDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsParsingService.adsParsingServiceService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS Git Service Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsGitService.adsGitServiceDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsGitService.adsGitServiceService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS Download Service Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsDownloadService.adsDownloadServiceDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsDownloadService.adsDownloadServiceService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsDownloadService.adsDownloadServiceZenIntegration' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS REST API Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsRestApi.adsRestApiDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsRestApi.adsRestApiService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsRestApi.adsRestApiZenIntegration' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS Front Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsFront.adsFrontDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsFront.adsFrontService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsFront.adsFrontZenIntegration' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS Build Service Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsBuildService.adsBuildServiceDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsBuildService.adsBuildServiceService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS Credentials Service Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsCredentialsService.adsCredentialsServiceDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsCredentialsService.adsCredentialsServiceService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS RR Registration Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsRrRegistration.adsRrRegistrationJob' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS Credentials Service Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsRuntimeService.adsRuntimeServiceDeployment' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsRuntimeService.adsRuntimeServiceService' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsRuntimeService.adsRuntimeServiceZenIntegration' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Wait for ADS Runtime BAI Registration Ready states"
wait_for_k8s_resource_condition_generic ICP4ACluster/${CP4BA_CR_META_NAME} '.status.components.adsRuntimeBaiRegistration.adsRuntimeBaiRegistrationJob' Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

wait_for_cp4ba ${CP4BA_CR_META_NAME} ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) CP4BA deploy install completed"
