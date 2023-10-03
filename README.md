# Installation of Cloud Pak for Business Automation on containers - Apollo one-shot deployment 🔫 <!-- omit in toc -->

📢📢📢**This repository has been merged to Cloud Pak Deployer**🚀🚀🚀  
**Read further to get to know how to use it**

Original README.md of Apollo one-shot is located at [README-orig.md](README-orig.md)


- [Disclaimer ✋](#disclaimer-)
- [Move to Cloud Pak Deployer (CPD) 🚀](#move-to-cloud-pak-deployer-cpd-)
  - [1. Create new Project](#1-create-new-project)
  - [2. Assign permissions](#2-assign-permissions)
  - [3. Add configuration](#3-add-configuration)
  - [4. Run the Job](#4-run-the-job)
- [Contacts](#contacts)
- [Notice](#notice)

## Disclaimer ✋

This is **not** an official IBM documentation.  
Absolutely no warranties, no support, no responsibility for anything.  
Use it on your own risk and always follow the official IBM documentations.  
It is always your responsibility to make sure you are license compliant.

## Move to Cloud Pak Deployer (CPD) 🚀

Main repository at https://github.com/IBM/cloud-pak-deployer  
Docs entry point at https://ibm.github.io/cloud-pak-deployer  
CP4BA reference in docs at https://ibm.github.io/cloud-pak-deployer/30-reference/configuration/cloud-pak/#cp4ba  
CP4BA Additional details in docs at https://ibm.github.io/cloud-pak-deployer/30-reference/configuration/cp4ba  

You need to get rid of the One-shot deployment at first. You can use the following remove Job. And then remove whole apollo-one-shot Project.
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  generateName: apollo-one-shot-remove-
  namespace: apollo-one-shot
spec:
  template:
    metadata:
      labels:
        app: apollo-one-shot  
    spec:
      containers:
        - name: apollo-one-shot
          image: ubi9/ubi:9.0.0
          command: ["/bin/bash"]
          args:
            ["-c","cd /usr; yum install git -y && git clone --depth 1 --shallow-submodules --progress --branch ${GIT_BRANCH} ${GIT_REPOSITORY}; cd ./ibm-cp4ba-enterprise-deployment/scripts; chmod u+x apollo-one-shot.sh; ./apollo-one-shot.sh"]
          imagePullPolicy: IfNotPresent
          env:
            - name: ACTION
              value: remove
            - name: GIT_REPOSITORY
              valueFrom:
                configMapKeyRef:
                  name: apollo-one-shot
                  key: git_repository
            - name: GIT_BRANCH
              value: main
            - name: CONTAINER_RUN_MODE
              value: "true"
          volumeMounts:
            - name: config
              mountPath: /config/
      restartPolicy: Never
      volumes:
        - name: config
          configMap:
            name: apollo-one-shot
  backoffLimit: 2
```

Apollo one-shot like deployment from OpenShift console based on https://ibm.github.io/cloud-pak-deployer/50-advanced/run-on-openshift/run-deployer-on-openshift-using-console/

### 1. Create new Project

```yaml
apiVersion: v1
kind: Namespace
metadata:
  creationTimestamp: null
  name: cloud-pak-deployer
```

### 2. Assign permissions

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cloud-pak-deployer-sa
  namespace: cloud-pak-deployer
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: system:openshift:scc:privileged
  namespace: cloud-pak-deployer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:openshift:scc:privileged
subjects:
- kind: ServiceAccount
  name: cloud-pak-deployer-sa
  namespace: cloud-pak-deployer
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cloud-pak-deployer-cluster-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: cloud-pak-deployer-sa
  namespace: cloud-pak-deployer
```

### 3. Add configuration

Customize
- `TODO_RWX_FILE_STORAGE_CLASS` - RFX File Storage class for PVC where the deployer stores its runtime data
- `TODO_ICR_PASSWORD` - password for IBM Container Registry from https://myibm.ibm.com/products-services/containerlibrary
- `TODO_UNIVERSAL_PASSWORD` - Password which will be used for all user credentials in the deployment
- `TODO_OCP_VERSION` - your OpenShift version, only x.y like 4.10, 4.11, 4.12

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cloud-pak-deployer-status
  namespace: cloud-pak-deployer
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: TODO_RWX_FILE_STORAGE_CLASS
---
apiVersion: v1
kind: Secret
metadata:
  name: cloud-pak-entitlement-key
  namespace: cloud-pak-deployer
type: Opaque
stringData:
  cp-entitlement-key: |
    TODO_ICR_PASSWORD
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: cloud-pak-deployer-config
  namespace: cloud-pak-deployer
data:
  cpd-config.yaml: |
    global_config:
      cloud_platform: existing-ocp
      env_id: cp4ba
      environment_name: sample
      universal_password: TODO_UNIVERSAL_PASSWORD

    openshift:
    - cluster_name: "{{ env_id }}"
      domain_name: example.com
      name: "{{ env_id }}"
      ocp_version: "TODO_OCP_VERSION"
      console_banner: "{{ env_id }}"
      openshift_storage:
      - storage_name: auto-storage
        storage_type: auto

    cp4ba:
    - project: cp4ba
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
```

### 4. Run the Job

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  labels:
    app: cloud-pak-deployer
  name: cloud-pak-deployer
  namespace: cloud-pak-deployer
spec:
  parallelism: 1
  completions: 1
  backoffLimit: 0
  template:
    metadata:
      name: cloud-pak-deployer
      labels:
        app: cloud-pak-deployer
    spec:
      containers:
      - name: cloud-pak-deployer
        image: quay.io/cloud-pak-deployer/cloud-pak-deployer:latest
        imagePullPolicy: Always
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        env:
        - name: CONFIG_DIR
          value: /Data/cpd-config
        - name: STATUS_DIR
          value: /Data/cpd-status
        - name: CP_ENTITLEMENT_KEY
          valueFrom:
            secretKeyRef:
              key: cp-entitlement-key
              name: cloud-pak-entitlement-key
        volumeMounts:
        - name: config-volume
          mountPath: /Data/cpd-config/config
        - name: status-volume
          mountPath: /Data/cpd-status
        command: ["/bin/sh","-xc"]
        args: 
          - /cloud-pak-deployer/cp-deploy.sh env apply -v
      restartPolicy: Never
      securityContext:
        runAsUser: 0
      serviceAccountName: cloud-pak-deployer-sa
      volumes:
      - name: config-volume
        configMap:
          name: cloud-pak-deployer-config
      - name: status-volume
        persistentVolumeClaim:
          claimName: cloud-pak-deployer-status
```

## Contacts

Jan Dusek  
jdusek@cz.ibm.com  
Business Automation Technical Specialist  
IBM Czech Republic

Ondrej Svec  
ondrej.svec2@ibm.com  
Automation Engineer  
IBM Client Engineering CEE  

## Notice

© Copyright IBM Corporation 2021.
