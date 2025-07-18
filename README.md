# Installation of Cloud Pak for Business Automation on containers - Cloud Pak Deployer (formerly Apollo one-shot deployment) 🔫 <!-- omit in toc -->

- [Disclaimer ✋](#disclaimer-)
- [Deploy CP4BA using Cloud Pak Deployer (CPD) 🚀](#deploy-cp4ba-using-cloud-pak-deployer-cpd-)
- [Removal](#removal)
- [Contacts](#contacts)
- [Notice](#notice)

## Disclaimer ✋

This is **not** an official IBM documentation.  
Absolutely no warranties, no support, no responsibility for anything.  
Use it on your own risk and always follow the official IBM documentations.  
It is always your responsibility to make sure you are license compliant.

## Deploy CP4BA using Cloud Pak Deployer (CPD) 🚀

Main repository at https://github.com/IBM/cloud-pak-deployer  
Docs entry point at https://ibm.github.io/cloud-pak-deployer  
CP4BA reference in docs at https://ibm.github.io/cloud-pak-deployer/30-reference/configuration/cloud-pak/#cp4ba  
CP4BA Additional details in docs at https://ibm.github.io/cloud-pak-deployer/30-reference/configuration/cp4ba  

Follow the guide on https://ibm.github.io/cloud-pak-deployer/10-use-deployer/3-run/existing-openshift-console/

In the [Configure the Cloud Paks and services to be deployed](https://ibm.github.io/cloud-pak-deployer/10-use-deployer/3-run/existing-openshift-console/#configure-the-cloud-paks-and-services-to-be-deployed) section, modify and provide the following configuration for CP4BA instead of the one from the documentation for CP4D.

Customize:
- `universal_password` - Only alphanumeric (no special characters) password which will be used for all user credentials in the deployment. Will be generated if not provided.
- `ocp_version` - Your OpenShift version, only x.y like 4.12, 4.14
- As needed the `cp4ba:` section as per documentation at https://ibm.github.io/cloud-pak-deployer/30-reference/configuration/cloud-pak/#cp4ba  

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: cloud-pak-deployer-config
  namespace: cloud-pak-deployer
data:
  cpd-config.yaml: |
    global_config:
      environment_name: cp4ba
      cloud_platform: existing-ocp
      env_id: cp4ba
      universal_password: ''

    openshift:
    - cluster_name: "{{ env_id }}"
      domain_name: example.com
      name: "{{ env_id }}"
      ocp_version: 4.15
      console_banner: "{{ env_id }}"
      openshift_storage:
      - storage_name: auto-storage
        storage_type: auto

    cp4ba:
    - project: cp4ba
      collateral_project: cp4ba-collateral
      openshift_cluster_name: "{{ env_id }}"
      openshift_storage_name: auto-storage
      accept_licenses: true
      state: installed
      cpfs_profile_size: small # Profile size which affect replicas and resources of Pods of CPFS as per https://www.ibm.com/docs/en/cpfs?topic=operator-hardware-requirements-recommendations-foundational-services

      # Section for Cloud Pak for Business Automation itself
      cp4ba:
        # Set to false if you don't want to install (or remove) CP4BA
        enabled: true # Currently always true
        profile_size: small # Profile size which affect replicas and resources of Pods as per https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/latest?topic=pcmppd-system-requirements
        patterns:
          foundation: # Foundation pattern, always true - https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/22.0.2?topic=deployment-capabilities-production-deployments#concept_c2l_1ks_fnb__foundation
            optional_components:
              bas: true # Business Automation Studio (BAS) 
              bai: true # Business Automation Insights (BAI)
              ae: true # Application Engine (AE)
          decisions: # Operational Decision Manager (ODM) - https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/22.0.2?topic=deployment-capabilities-production-deployments#concept_c2l_1ks_fnb__odm
            enabled: true
            optional_components:
              decision_center: true # Decison Center (ODM)
              decision_runner: true # Decison Runner (ODM)
              decision_server_runtime: true # Decison Server (ODM)
            # Additional customization for Operational Decision Management
            # Contents of the following will be merged into ODM part of CP4BA CR yaml file. Arrays are overwritten.
            cr_custom:
              spec:
                odm_configuration:
                  decisionCenter:
                    # Enable support for decision models
                    disabledDecisionModel: false
          decisions_ads: # Automation Decision Services (ADS) - https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/22.0.2?topic=deployment-capabilities-production-deployments#concept_c2l_1ks_fnb__ads
            enabled: true
            optional_components:
              ads_designer: true # Designer (ADS)
              ads_runtime: true # Runtime (ADS)
            gen_ai: # https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/latest?topic=services-configuring-generative-ai-secret
              apiKey: watsonx_ai_api_key
              mlUrl: https://us-south.ml.cloud.ibm.com
              projectId: project_id
          content: # FileNet Content Manager (FNCM) - https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/22.0.2?topic=deployment-capabilities-production-deployments#concept_c2l_1ks_fnb__ecm
            enabled: true
            optional_components:
              cmis: true # Content Management Interoperability Services (FNCM - CMIS)
              css: true # Content Search Services (FNCM - CSS)
              es: true # External Share (FNCM - ES)
              tm: true # Task Manager (FNCM - TM)
              ier: true # IBM Enterprise Records (FNCM - IER)
              icc4sap: false # IBM Content Collector for SAP (FNCM - ICC4SAP) - Currently not implemented
          application: # Business Automation Application (BAA) - https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/22.0.2?topic=deployment-capabilities-production-deployments#concept_c2l_1ks_fnb__baa
            enabled: true
            optional_components:
              app_designer: true # App Designer (BAA)
              ae_data_persistence: true # App Engine data persistence (BAA)
          document_processing: # Automation Document Processing (ADP) - https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/22.0.2?topic=deployment-capabilities-production-deployments#concept_c2l_1ks_fnb__adp
            enabled: true
            optional_components: 
              document_processing_designer: true # Designer (ADP)
            # Additional customization for Automation Document Processing
            # Contents of the following will be merged into ADP part of CP4BA CR yaml file. Arrays are overwritten.
            cr_custom:
              spec:
                ca_configuration:
                  # GPU config as described on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/22.0.1?topic=resource-configuring-document-processing
                  deeplearning:
                    gpu_enabled: false
                    nodelabel_key: nvidia.com/gpu.present
                    nodelabel_value: "true"
                  ocrextraction:
                    use_iocr: none # Allowed values: "none" to uninstall, "all" or "auto" to install (these are aliases)                         
          workflow: # Business Automation Workflow (BAW) - https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/22.0.1?topic=deployment-capabilities-production-deployments#concept_c2l_1ks_fnb__baw
            enabled: true
            optional_components:
              baw_authoring: true # Workflow Authoring (BAW) - always keep true if workflow pattern is chosen. BAW Runtime is not implemented.
              kafka: true # Will install a kafka cluster and enable kafka service for workflow authoring.
            gen_ai: # https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/25.0.0?topic=customizing-enabling-generative-ai
              apiKey: watsonx_ai_api_key
              mlUrl: https://us-south.ml.cloud.ibm.com
              projectId: project_id
              defaultFoundationModel: meta-llama/llama-3-3-70b-instruct
      
      # Section for IBM Process mining
      pm:
        # Set to false if you don't want to install (or remove) Process Mining
        enabled: true
        # Additional customization for Process Mining
        # Contents of the following will be merged into PM CR yaml file. Arrays are overwritten.
        cr_custom:
          spec:
            processmining:
              storage:
                # Disables redis to spare resources as per https://www.ibm.com/docs/en/process-mining/1.13.2?topic=configurations-custom-resource-definition
                redis:
                  install: false  

      # Section for IBM Robotic Process Automation
      rpa:
        # Set to false if you don't want to install (or remove) RPA
        enabled: true
        # Additional customization for Robotic Process Automation
        # Contents of the following will be merged into RPA CR yaml file. Arrays are overwritten.
        cr_custom:
          spec:
            # Configures the NLP provider component of IBM RPA. You can disable it by specifying 0. https://www.ibm.com/docs/en/rpa/21.0?topic=platform-configuring-rpa-custom-resources#basic-setup
            nlp:
              replicas: 1

      # Section for Asset Repository
      asset_repo:
        # Set to false if you don't want to install (or remove) Asset Repo
        enabled: false # Currently not implemented

      # Set to false if you don't want to install (or remove) CloudBeaver (PostgreSQL, DB2, MSSQL UI)
      cloudbeaver_enabled: true

      # Set to false if you don't want to install (or remove) Roundcube
      roundcube_enabled: true

      # Set to false if you don't want to install (or remove) Cerebro
      cerebro_enabled: true

      # Set to false if you don't want to install (or remove) AKHQ
      akhq_enabled: true

      # Set to false if you don't want to install (or remove) Mongo Express
      mongo_express_enabled: true
      
      # Set to false if you don't want to install (or remove) phpLDAPAdmin
      phpldapadmin_enabled: true

      # Set to false if you don't want to install (or remove) OpenSearch Dashboards
      opensearch_dashboards_enabled: true
```

## Removal

To remove CP4BA deployment, edit the main configmap
```yaml
kind: ConfigMap
metadata:
  name: cloud-pak-deployer-config
  namespace: cloud-pak-deployer
```

Update state to removed
```yaml
    cp4ba:
    - project: cp4ba
      openshift_cluster_name: "{{ env_id }}"
      openshift_storage_name: auto-storage
      accept_licenses: true
      state: removed # Change from installed
```

Reapply the Pod from step [Start the Deployer](https://ibm.github.io/cloud-pak-deployer/10-use-deployer/3-run/existing-openshift-console/#start-the-deployer). It knows that it should remove the deployment based on the parameter in the ConfigMap.

## Contacts

Jan Dusek  
jdusek@cz.ibm.com  
Business Automation Technical Specialist  
IBM Czech Republic

## Notice

© Copyright IBM Corporation 2021.
