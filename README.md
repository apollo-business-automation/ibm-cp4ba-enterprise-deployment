# Installation of Cloud Pak for Business Automation on containers - Apollo one-shot enterprise deployment 🔫 <!-- omit in toc -->

Goal of this repository is to almost automagically install CP4BA Enterprise patterns and also IAF components with all kinds of prerequisites and extras on OpenShift.

Last installation was performed on 2022-09-20 with CP4BA version 22.0.1-IF002 (also called 22.0.1.2 or 21.1.2)

- [Disclaimer ✋](#disclaimer-)
- [Documentation base](#documentation-base)
- [Benefits 🚀](#benefits-)
- [General information 📢](#general-information-)
- [What is in the package 📦](#what-is-in-the-package-)
- [Environments used for installation 💻](#environments-used-for-installation-)
- [Pre-requisites ⬅️](#pre-requisites-️)
- [Installation steps ⚡](#installation-steps-)
- [Post installation steps ➡️](#post-installation-steps-️)
- [Usage & operations 😊](#usage--operations-)
- [Update steps ↗️](#update-steps-)
- [Removal steps 🗑️](#removal-steps-️)
- [Post removal steps ➡️](#post-removal-steps-️)
- [Contacts](#contacts)
- [Notice](#notice)

## Disclaimer ✋

This is **not** an official IBM documentation.  
Absolutely no warranties, no support, no responsibility for anything.  
Use it on your own risk and always follow the official IBM documentations.  
It is always your responsibility to make sure you are license compliant when using this repository to install IBM Cloud Pak for Business Automation.

Please do not hesitate to create an issue here if needed. Your feedback is appreciated.

Not for production use. Suitable for Demo and PoC environments - but with enterprise deployment.  

**!Important** - Keep in mind that the platform contains DB2 which is licensed with Standard Edition license available from CP4BA and it must adhere to the *Additional IBM DB2 Standard Edition Detail* in official license information at http://www-03.ibm.com/software/sla/sladb.nsf/doclookup/F2925E0D5C24EAB4852586FE0060B3CC?OpenDocument (or its newer revision).

**!Important** - Keep in mind that this deployment contains capabilities (the ones which are not bundled with CP4BA) which are not eligible to run on Worker Nodes covered by CP4BA OCP Restricted licenses. More info on https://www.ibm.com/docs/en/cloud-paks/1.0?topic=clusters-restricted-openshift-entitlement.

## Documentation base

Deploying CP4BA is based on official documentation which is located at https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/22.0.1.

Deployment of other parts is also based on respective official documentations.

- IBM Robotic Process Automation (RPA) https://www.ibm.com/docs/en/cloud-paks/1.0?topic=automation-planning-rpa-openshift
- IBM Automation Assets https://www.ibm.com/docs/en/cloud-paks/1.0?topic=foundation-automation-assets
- IBM Process Mining https://www.ibm.com/docs/en/cloud-paks/1.0?topic=pm-installation-setup-guide-process-mining-openshift-container-platform
- IBM Automation Foundation (IAF) https://www.ibm.com/docs/en/cloud-paks/1.0?topic=automation-foundation
- IBM Cloud Pak Foundational Services (CPFS) https://www.ibm.com/docs/en/cpfs?topic=operator-installing-foundational-services-online

## Benefits 🚀

- Automatic deployment of the whole platform where you don't need to take care about almost any prerequisites
- Common Global CA used to sign all certificates so there is only one certificate you need to trust in you local machine to trust all URLs of the whole platform
- Trusted certificate in browser also enable you to save passwords
- Wherever possible a common admin user *cpadmin* with adjustable password is used so you don't need to remember multiple credentials when you want to access the platform (convenience also comes with responsibility - so you don't want to expose your platform to whole world)
- The whole platform is running on containers so you don't need to manually prepare anything on traditional VMs and take care of them including required prerequisites
- Many otherwise manual post-deployment steps have been automated
- Pre integrated and automatically connected extras are deployed in the platform for easier access/management/troubleshooting
- You have a working starting Enterprise deployment which you can use as a reference for further custom deployments

## General information 📢

Result of this Enterprise deployment is not fully supported:
- For convenience, it contains OpenLDAP as a directory provider which is not supported - in real deployments this needs to be replaced with a supported directory provider
- For convenience and lower resource consumption, it uses one containerized DB2 database and schemas for majority of required DBs - in real deployments a supported DB option described on "[Compatibility matrix](https://www.ibm.com/software/reports/compatibility/clarity-reports/report/html/softwareReqsForProduct?deliverableId=71C22290D7DB11EBAA175CFD3E629A2A&osPlatforms=Linux%7CMac%20OS%7CWindows&duComponentIds=D010%7CD009%7CD011%7CS015%7CS014%7CS013%7CC027%7CC032%7CC017%7CC024%7CC023%7CC029%7CC018%7CC021%7CC022%7CC030%7CC028%7CC020%7CC025%7CC031%7CC016%7CC034%7CC019%7CC026&mandatoryCapIds=71%7C26&optionalCapIds=134%7C62%7C127%7C9%7C401%7C132%7C20%7C161) > Supported Software > Databases" would be used

What is not included:
- ICCs - not covered.
- Caution! FNCM External share - Currently not supported with ZEN & IAM as per limitation on [FNCM limitations](https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/22.0.1?topic=notes-known-limitations-issues#concept_gmf_x1h_1fb__ecm)
- Caution! Asset Repository is now omitted due to a bug in IAF - waiting for fixes. And the latest version only support OCP 4.10+.
- Workflow Server and Workstream Services - this is a dev deployment. BAW Authoring and (BAW + IAWS) are mutually exclusive in single project.

## What is in the package 📦

When you perform full deployment, as a result you will get full CP4BA platform as seen in the picture. You can also omit some capabilities - this is covered later in this doc.

More details about each section from the picture follows below it.

![assets/cp4ba-installation.png](assets/cp4ba-installation.png)

### Extras section

Contains extra software which makes working with the platform even easier.

- DB2MC - Web UI for DB2 database making it easier to admin and troubleshoot the DB.
- phpLDAPadmin - Web UI for OpenLDAP directory making it easier to admin and troubleshoot the LDAP.
- Gitea - Contains Git server with web UI and is used for ADS and ADP for project sharing and publishing. Organizations for ADS and APD are automatically created. Gitea is connected to OpenLDAP for authentication and authorization.
- Nexus - Repository manager which contains pushed ADS java libraries needed for custom development and also for publishing custom ADS jars. Nexus is connected to OpenLDAP for authentication and authorization.
- Roundcube - Web UI for included Mail server to be able to browse incoming emails.
- Cerebro - Web UI elastic search browser automatically connected to ES instance deployed with CP4BA.
- AKHQ - Web UI kafka browser automatically connected to Kafka instance deployed with CP4BA.
- Kibana - Web UI elastic search dashboarding tool automatically connected to ES instance deployed with CP4BA.
- Mail server - For various mail integrations e.g. from BAN, BAW and RPA.
- Mongo Express - Web UI for Mongo DB databases for CP4BA and Process Mining to easier troubleshoot DB.

### CP4BA (Cloud Pak for Business Automation) section

#### CP4BA capabilities

Purple color is used for CP4BA capabilities.

More info for these capabilities is available in official docs at https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/22.0.1.

More specifically in overview of patterns at https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/22.0.1?topic=deployment-capabilities-production-deployments.

#### IAF (IBM Automation Foundation) capabilities

Pink color is used for IAF capabilities.

More info for these capabilities is available in official docs at https://www.ibm.com/docs/en/cloud-paks/1.0?topic=automation-foundation.

### CPFS (Cloud Pak Foundational Services) section

Contains services which are reused by Cloud Paks.

More info available in official docs at https://www.ibm.com/docs/en/cpfs.

- Monitoring - Contains Grafana instance for custom dashboarding.
- License metering - Tracks license usage. License Reporter as Web UI is also installed.
- IAM - Provides Identity and Access management.
- Health Checking - Enables you to generate MusthGather output which is useful for support.

### Pre-requisites section

Contains prerequisites for the whole platform.

- DB2 - Database storage for Capabilities which need it.
- OpenLDAP - Directory solution for users and groups definition.
- MSSQL server - Database storage for RPA server.
- MongoDB - Database storage for ADS and Process Mining.

### Deployment job section

Multiple command line tools are installed inside a container to make the installation possible.

- Global CA - Generated self-signed Certification Authority via OpenSSL to make trusting the platform easier. It is also possible to provide your own CA and how to do so is described later in this doc.
- helm - Used for helm charts installation (https://helm.sh/docs/).

## Environments used for installation 💻

With proper sizing of the cluster and provided RWX Storage Class, this guide should be working on any OpenShift 4.10 with 8 Worker Nodes (16 CPU, 32GB Memory each), however it was historically executed on the following once.  
OpenShift 4.8 will not work with asset repository enabled.

- ROKS - RedHat OpenShift Kubernetes Service allowing to run managed Red Hat OpenShift on IBM Cloud  
OpenShift 4.8.x & 4.10.x - 8 Worker Nodes (16 CPU, 32GB Memory) - Managed NFS Storage Class  
Successfully installed

- Traditional OpenShift cluster created from scratch on top of virtualization platform  
OpenShift 4.8.x & 4.10.x on vms - 7 Worker Nodes (16 CPU, 32GB Memory) - Managed NFS Storage Class  
Successfully installed

- ARO - Azure Red Hat OpenShift allowing to run managed Red Hat OpenShift on Azure - not tested recently  
OpenShift 4.8.x - 7 Worker Nodes (16 CPU, 32GB Memory) - ODF (OCS) with ocs-storagecluster-cephfs Strorage Class  
Successfully installed

- ROSA - Red Hat OpenShift Service on AWS - not tested recently  
OpenShift 4.8.x - 7 Worker Nodes (16 CPU, 32GB Memory) - ODF (OCS) with ocs-storagecluster-cephfs Strorage Class  
Successfully installed **but has issues** with passthrough Routes malfunction making it hard to access the platform.

The following picture shows real idle utilization of Nodes with deployed platform on above mentioned ROKS as an example.

![assets/utilization.png](assets/utilization.png)

The following output shows CPU and Memory requests and limits on Nodes on above mentioned ROKS as an example.

```text
node/10.162.243.84
  Resource           Requests          Limits
  cpu                10486m (66%)      34610m (217%)
  memory             22192659Ki (76%)  51245344Ki (176%)

node/10.162.243.97
  Resource           Requests          Limits
  cpu                13010m (81%)      37770m (237%)
  memory             24835603Ki (85%)  48728352Ki (168%)

node/10.163.57.153
  Resource           Requests          Limits
  cpu                11240m (70%)      102585m (646%)
  memory             22581779Ki (77%)  120447264Ki (415%)

node/10.163.57.158
  Resource           Requests          Limits
  cpu                11391m (71%)      41210m (259%)
  memory             23807507Ki (82%)  54913312Ki (189%)

node/10.163.57.252
  Resource           Requests          Limits
  cpu                10498m (66%)      53400m (336%)
  memory             22762003Ki (78%)  69994784Ki (241%)

node/10.163.57.254
  Resource           Requests          Limits
  cpu                9741m (61%)       38750m (244%)
  memory             22034011Ki (76%)  52342048Ki (180%)
```

## Pre-requisites ⬅️

- OpenShift cluster sized according with the system requirements
  - Cloud Pak: https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/22.0.1?topic=pcmppd-system-requirements
  - RPA: https://www.ibm.com/docs/en/cloud-paks/1.0?topic=openshift-pre-installation-requirements
  - Process Mining: https://www.ibm.com/docs/en/cloud-paks/1.0?topic=platform-pre-installation-requirements
  - IAF : https://www.ibm.com/docs/en/cloud-paks/1.0?topic=p-system-requirements
  - CPFS: https://www.ibm.com/docs/en/cpfs?topic=services-hardware-requirements-starterset-profile
- OpenShift cluster admin access
- Access to public internet from OpenShift
- Software entitlement key for IBM software which is found at https://myibm.ibm.com/products-services/containerlibrary

## Installation steps ⚡

The following steps instructs you to create new OpenShift resources via YAML files.

You can apply them via OpenShift console (with the handy *plus* icon at the top right - Import YAML) or *oc* CLI from your machine.

![assets/installation-steps.png](assets/installation-steps.png)

### 1. Create new Project

At first, create new *apollo-one-shot* Project by applying the following yaml (also see the picture below the YAML).

This Project is used to house other resources needed for the Apollo one-shot deployment.

```yaml
kind: Project
apiVersion: project.openshift.io/v1
metadata:
  name: apollo-one-shot
```

![assets/project.png](assets/project.png)

### 2. Assign permissions

This requires the logged in OpenShift user to be cluster admin.

Now you need to assign cluster admin permissions to *apollo-one-shot* default ServiceAccount under which the installation is performed by applying the following yaml (also see the picture below the YAML).

The ServiceAccount needs to have cluster admin to be able to create all resources needed to deploy the platform.

```yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cluster-admin-apollo-one-shot
subjects:
  - kind: User
    apiGroup: rbac.authorization.k8s.io
    name: "system:serviceaccount:apollo-one-shot:default"
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
```

![assets/cluster-role-binding.png](assets/cluster-role-binding.png)

### 3. Add configuration

The installation process needs configuration information properly adjusted to your environment.

Copy the contents of the following yaml to OpenShift console *Import YAML* dialog (as seen in the picture below - point 1 and 2).

Update variables in *variables.yml* entry as wanted (as seen in the picture below - point 2, row starting with *variables.sh*). Keys are divided into sections and every key is documented for you to understand what to fill in it.

You can also choose not to deploy the whole platform by setting various feature variables to *false*.  

Apply the updated contents to your cluster (as seen in the picture below point 3).

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: apollo-one-shot
  namespace: apollo-one-shot
data:
  # Repository url can be changed to you own forked repository with your customizations
  git_repository: https://github.com/apollo-business-automation/ibm-cp4ba-enterprise-deployment.git

  # This parameter cotains a specific tag name of the repository. This allows you to run Install and Remove from the same version.
  # In situation where you want to clean and install newver version you leave the original tag you had, run through remove and then change this tag to lastest and run install.
  git_branch: main

  # Variables
  variables.yml: |
    # Mandatory - Always set these parameters to your values #

    ## Entitlement key from the IBM Container software library. 
    ## (https://myibm.ibm.com/products-services/containerlibrary)  
    icr_password: TODO_ICR_PASSWORD

    ## Name of the StorageClass used for all PVCs which must be already present in your OpenShift. 
    ## Must be RWX and Fast.
    ## For ROKS this class could be ibmc-file-gold-gid (But strongly discouraged due to slow PVC binding)
    ## For NFS based class this could be managed-nfs-storage
    ## For ODF (OCS) based class (e.g. on ARO or ROSA) this could be ocs-storagecluster-cephfs
    storage_class_name: managed-nfs-storage

    ## Options are OCP and ROKS (ROKS is specific to managed OpenShift on IBM Cloud)
    ## OCP option also applies to other managed OpenShifts ( like ARO, ROSA, etc. )
    deployment_platform: ROKS

    ## In the Platform, multiple users and keystores and other encrypted entries need a password.
    ## To make working with the Platform easier all places which require a password share the same one from this variable.
    ## Make this password strong to ensure that no one from the outside world can login to your Platform.
    ## Password must be alphanumeric (upper and lower case; no special characters allowed).
    universal_password: Passw0rd

    # Optional - The rest of the following parameters can be used to further customize the deployment.
    
    # You don't need to configure them in any way if you want to just install the whole platform with prerequisites and extras.

    ## Set to false if you provide your own LDAP, madatory to set the ldap_configuration
    openldap_enabled: true

    # apollo-one-shot deployment installs its own OpenLdap server. 
    # If you do not want to use it and have an external LDAP server you prefer, then uncomment the ldap_configuration and fill the values.
    # Example values are provided bellow.
    # Documented in: https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/22.0.1?topic=parameters-ldap-configuration
    #
    # IMPORTANT: The provided LDAP will be used for all the components you are going to install.
    # IMPORTANT: Also set openldap_enabled on false if you do not want to install it
    # IMPORTANT: Also fill the values in apollo-one-shot secret that is bellow
    # 
    #ldap_configuration:
    ## the main ldap group used for workflow and other purposes where single group of admins is required. 
    #  lc_principal_admin_group: cpadmins
    ## list of all admin groups you want to set to be admins in the platform components 
    #  lc_admin_groups: ['cpadmins'] 
    ## explicit list of users to be admins of the platform componets
    #  lc_admin_users: ['cpadmin']
    ## list of general user groups
    #  lc_general_groups: ['cpusers','cpusers1']
    #  lc_selected_ldap_type: IBM Security Directory Server
    #  lc_ldap_server: "external_ldap_hostname"
    #  lc_bind_secret: ldap-bind-secret
    #  lc_ldap_domain: cp.local
    #  lc_ldap_base_dn: dc=cp,dc=local
    #  lc_ldap_user_base_dn: ou=Users,dc=cp,dc=local
    ## If you decide to use ssl with ldap, be sure to provide lc_ldap_ssl_secret_name as well
    ## documentation: https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/22.0.1?topic=resource-configuring-ssl-enabled-ldap
    #  lc_ldap_ssl_enabled: false
    #  lc_ldap_ssl_secret_name: "external_ldap_ssl_secret_name"
    #  lc_ldap_user_object_class: inetOrgPerson
    #  lc_ldap_user_id_attribute: uid
    #  lc_ldap_user_name_attribute: "*:cn"
    #  lc_ldap_user_display_name_attr: cn
    #  lc_ldap_group_object_class: groupOfNames
    #  lc_ldap_group_id_attribute: cn
    #  lc_ldap_group_base_dn: ou=Groups,dc=cp,dc=local
    #  lc_ldap_group_name_attribute: "*:cn"
    #  lc_ldap_group_display_name_attr: cn
    #  lc_ldap_group_membership_search_filter: "(|(&(objectclass=groupofnames)(member={0}))(&(objectclass=groupofuniquenames)(uniquemember={0})))"
    #  lc_ldap_group_member_id_map: "groupofnames:member"
    #  tds:
    #    lc_user_filter: "(&(cn=%v)(objectclass=inetOrgPerson))"
    #    lc_group_filter: "(&(cn=%v)(|(objectclass=groupofnames)(objectclass=groupofuniquenames)(objectclass=groupofurls)))"

    # Configuration of cp4ba components to be installed. Please be sure you select all that is needed both from the 
    # deployment patterns as well as from the optional components.
    # Dependencies can be determined from documentation at https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/22.0.1?topic=deployment-capabilities-production-deployments
    # Only some combinations were tested.
    cp4ba_config:
      deployment_patterns:
        foundation: true
        decisions: true
        decisions_ads: true
        content: true
        application: true
        document_processing: true
        workflow: true
        workflow_workstreams: false
      optional_components:
        bas: true
        bai: true
        decision_center: true
        decision_runner: true
        decision_server_runtime: true
        ads_designer: true
        ads_runtime: true
        cmis: true
        # css: Content Search Services
        css: true
        # es = External Share
        es: true
        # tm = Task Management
        tm: true
        # ier = IBM Enterprise Records
        ier: true
        app_designer: true
        ae_data_persistence: true
        document_processing_designer: true
        document_processing_runtime: false
        baw_authoring: true
        application: true
    
    # Additional customization for Automation Document Processing
    # Contents of the following will be merged into ADP part of CP4BA CR yaml file. Arrays are overwriten.
    adp_cr_custom:
      spec:
        ca_configuration:
          # GPU config as described on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/22.0.1?topic=resource-configuring-document-processing
          deeplearning:
            gpu_enabled: false
            nodelabel_key: nvidia.com/gpu.present
            nodelabel_value: true
    
    # Additional customization for Robotic Process Automation
    # Contents of the following will be merged into RPA CR yaml file. Arrays are overwriten.
    rpa_cr_custom:
      spec:
        # Configures the NLP provider component of IBM RPA. Set atleast to 1 to enable it. https://www.ibm.com/docs/en/rpa/21.0?topic=platform-configuring-rpa-custom-resources#basic-setup
        nlp:
          replicas: 0

    ## Set to false if you don't want to install (or remove) Process Mining
    pm_enabled: true

    ## Set to false if you don't want to install (or remove) Asset Repo
    asset_repo_enabled: true

    ## Set to false if you don't want to install (or remove) RPA
    rpa_enabled: true

    ## Set to false if you don't want to install (or remove) AKHQ
    akhq_enabled: true

    ## Set to false if you don't want to install (or remove) Cerebro
    cerebro_enabled: true

    ## Set to false if you don't want to install (or remove) DB2 Management Console
    db2mc_enabled: true

    ## Set to false if you don't want to install (or remove) Roundcube
    roundcube_enabled: true

    ## Set to false if you don't want to install (or remove) Mongo Express
    mongo_express_enabled: true

```

![assets/config-map-variables.png](assets/config-map-variables.png)

![assets/config-map-add.png](assets/config-map-add.png)

Optionally you can create a secret as described below to add your own Global CA or to add external LDAP.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: apollo-one-shot
  namespace: apollo-one-shot
type: Opaque
stringData:

  # Global CA
  ## Optionally you can add your custom Global CA which is then used to generate all certificates for the whole platform.
  ## If you don't provide it, a new Global CA will be automatically generated for you.
  ## To generate your own, you can use the following command which generated Global CA with 10 years validity.
  ## openssl req -new -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes -out global-ca.crt -keyout global-ca.key -subj "/CN=Global CA"

  ## Add certificate of your Global CA to *global_ca_tls.crt* and key to *global_ca_tls.key*.

  ## Make sure the contents of CA files are properly indented to the same level like example contents.
  ## Private key can also have different header and footer than *-----BEGIN RSA PRIVATE KEY-----* and *-----END RSA PRIVATE KEY-----*

  ## Global CA certificate
  global_ca_tls.crt: |
    -----BEGIN CERTIFICATE-----
    MIIFCzCCAvOgAwIBAgIUXwA5bTQNXox7K5johiEi9MjqOK8wDQYJKoZIhvcNAQEL
    ...
    P3ACf/xtBm9/8Q3qaFRERnVj8RiXLK641aBaLsDD1rCtvD4UloSfZ95ZOyipDTg=
    -----END CERTIFICATE-----

  ## Global CA key
  global_ca_tls.key: |
    -----BEGIN RSA PRIVATE KEY-----
    MIIJKwIBAAKCAgEA18utJwF6y7sDEkItvwQ5LlspVF/p1fYAN2XTpHuYzocU7FRY
    ...
    Xv/NTjv7sM8aAmYOpR5JZ+nAwa7Y1hkrAybdbh3a4qES1LbrNVEMCLjwnHpkfOs=
    -----END RSA PRIVATE KEY-----

  # External LDAP 
  ## Optionally you can add your custom External LDAP Bind Secret to provide credentials for when you want to use your own LDAP
  ## and not the OpenLdap which is installed by default by the apollo-one-shot.
  ## This should be used together with the setting `openldap_enabled: false` and also `ldap_configuration`.
  ## Bellow you can find an example of the bind secret:

  ## IMPORTANT: based on the following values, new bind secret will be created in the CP4BA namespace for the CP4BA use.

  ## IMPORTANT: When using External LDAP, for the **principal admin user**,
  ## when user name attribute and id attribute is different and their value as well,
  ## it is known to cause issue with setup of FileNet domain.
  ## Be sure to provide admin user who has the same name as id for now (e.g. same cn as uid for example).
  ## Alternatively configure the ldap_configuration approprietly to avoid the issue.

  ## Used for the ldap binding in components needing to interact with LDAP 
  ldapUsername: cn=admin,dc=cp,dc=local
  ldapPassword: anAdminPassword
  ## Used as the main admin for the installed platform, cp4ba.
  principalAdminUsername: cpadmin
  principalAdminPassword: aCPadminPassword
```

### 4. Run the Job

Trigger the installation by applying the following YAML (also see the picture below the YAML).

This Job runs a Pod which performs the installation. It attempts 3 times to perform the install.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  generateName: apollo-one-shot-install-
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
            ["-c","cd /usr; yum install git -y && git clone --progress --branch ${GIT_BRANCH} ${GIT_REPOSITORY}; cd ./ibm-cp4ba-enterprise-deployment/scripts; chmod u+x apollo-one-shot.sh; ./apollo-one-shot.sh"]
          imagePullPolicy: IfNotPresent
          env:
            - name: ACTION
              value: install
            - name: GIT_REPOSITORY
              valueFrom:
                configMapKeyRef:
                  name: apollo-one-shot
                  key: git_repository
            - name: GIT_BRANCH
              valueFrom:
                configMapKeyRef:
                  name: apollo-one-shot
                  key: git_branch
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

![assets/install-job.png](assets/install-job.png)

Now you need to wait for a couple of hours 6-10 for the installation to complete depending on speed of your OpenShift and StorageClass binding.

You can watch progress in log of Pod which was created by the Job and its name starts with *apollo-one-shot-install-*. See below images to find the logs.

Find the pod of install Job.

![assets/install-job-pod.png](assets/install-job-pod.png)

Then open logs tab.

![assets/install-job-pod-log.png](assets/install-job-pod-log.png)

#### Successful install

Successful completion is determined by seeing that the Job is *Complete* (in the below picture point 1) and the pod is also *Completed* (in the below picture point 3).

![assets/success-install-job-pod.png](assets/success-install-job-pod.png)

Also near the end of pod log there will be indication that zero tasks failed (in the below picture point 1).  

![assets/success-install-job-log.png](assets/success-install-job-log.png)

Now continue with the [Post installation steps](#post-installation-steps-%EF%B8%8F) and then review [Usage & Operations](#usage--operations-).

#### Failed install

If something goes wrong, the Job is *Failed* (in the below picture point 1) and the pod has status *Error* (in the below picture point 3).

![assets/failed-install-job-pod.png](assets/failed-install-job-pod.png)

Also near the end of pod log there will be a message containing the word "Failed" (in the below picture point 1).

![assets/failed-install-job-log.png](assets/failed-install-job-log.png)

Further execution is stopped - and you need to troubleshoot why the installation failed, fix your environment and retry installation from step [4. Run the Job](#4-run-the-job).

If rerunning install doesn't help, you can also try to clean the cluster by following [Removal steps](#removal-steps-%EF%B8%8F) and after successful removal retry installation again.

## Post installation steps ➡️

Review and perform post deploy manual steps for CP4BA as specified in ConfigMap *cp4ba-postdeploy* in *postdeploy.md* file. See below images to find this file. It is best to copy the contents and open it in nice MarkDown editor like VSCode. 

![assets/cp4ba-postdeploy-cm.png](assets/cp4ba-postdeploy-cm.png)

![assets/cp4ba-postdeploy-md.png](assets/cp4ba-postdeploy-md.png)


Review and perform post deploy manual steps for RPA as specified in ConfigMap *rpa-postdeploy.md* in *postdeploy.md* file. See below images to find this file. It is best to copy the contents and open it in nice MarkDown editor like VSCode.

![assets/rpa-postdeploy-cm.png](assets/rpa-postdeploy-cm.png)

![assets/rpa-postdeploy-md.png](assets/rpa-postdeploy-md.png)

Review and perform post deploy manual steps for IPM as specified in ConfigMap *pm-postdeploy.md* in *postdeploy.md* file. See below images to find this file. It is best to copy the contents and open it in nice MarkDown editor like VSCode.

![assets/pm-postdeploy-cm.png](assets/pm-postdeploy-cm.png)

![assets/pm-postdeploy-md.png](assets/pm-postdeploy-md.png)

## Usage & operations 😊

Endpoints, access info and other useful information is available in Project *apollo-one-shot* in ConfigMap named *usage* in *usage.md* file after installation. It is best to copy the contents and open it in nice MarkDown editor like VSCode.

Specifically, if you haven't provided your own Global CA, review the section *Global CA* in this md file.

![assets/usage-cm.png](assets/usage-cm.png)

![assets/usage-md.png](assets/usage-md.png)

## Update steps ↗️

Useful when you want to install new version.

If you want to upgrade some parts of deployment you need to follow official documentations.

Otherwise the procedure consists of removing the deployment and installing its new version.

The key here is the **git_branch** attribute in **apollo-one-shot** ConfigMap. It determines which version is used for both installation and removal of the deployment.
To get new version on the already installed cluster, you would leave the value to the original one and go through the [Removal steps 🗑️](#removal-steps-️). Then you would change the value to newer git tag and go through [Installation steps ⚡](#installation-steps-) reviewing if something has changed in the ConfigMap or Secrets from your previous deployment.

## Removal steps 🗑️

Useful when you want to clean up your environment.

You can use it even if the deployment failed and everything was not deployed but expect to see some failures as script tries to remove things which doesn't exist. You can ignore such errors.

### 1. Run the Job

Trigger the removal by applying the following YAML (also see the picture below the YAML).

This Job runs a Pod which performs the removal. It attempts 3 times to perform the removal.

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
            ["-c","cd /usr; yum install git -y && git clone --progress --branch ${GIT_BRANCH} ${GIT_REPOSITORY}; cd ./ibm-cp4ba-enterprise-deployment/scripts; chmod u+x apollo-one-shot.sh; ./apollo-one-shot.sh"]
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
              valueFrom:
                configMapKeyRef:
                  name: apollo-one-shot
                  key: git_branch
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

![assets/remove-job.png](assets/remove-job.png)

Now you need to wait for some time (30 minutes to 1 hour) for the removal to complete depending on the speed of your OpenShift.

You can watch progress in log of Pod which was created by the Job and its name starts with *apollo-one-shot-remove-*. See below images to find the logs.

Find the pod of remove Job.

![assets/remove-job-pod.png](assets/remove-job-pod.png)

Then open logs tab.

![assets/remove-job-pod-log.png](assets/remove-job-pod-log.png)

#### Successful removal

Successful completion of removal is determined by seeing that the Job is *Complete* (in the below picture point 1) and the pod is also *Completed* (in the below picture point 3).

![assets/success-remove-job-pod.png](assets/success-remove-job-pod.png)

Also near the end of pod log there will be indication that zero tasks failed (in the below picture point 1).  

![assets/success-remove-job-log.png](assets/success-remove-job-log.png)

#### Failed removal

If something goes wrong, the Job is *Failed* (in the below picture point 1) and the pod has status *Error* (in the below picture point 3).

![assets/failed-remove-job-pod.png](assets/failed-remove-job-pod.png)

Also near the end of pod log there will be a message containing the word "Failed" (in the below picture point 1).

![assets/failed-remove-job-log.png](assets/failed-remove-job-log.png)

Further execution is stopped - and you need to troubleshoot why the removal failed, fix your environment and retry removal from step [1. Run the Job](#1-run-the-job).

### 2. Remove apollo-one-shot related resources

If you don't plan to repeat install or removal steps, you can remove whole *apollo-one-shot* Project following steps in the following picture.

![assets/project-delete.png](assets/project-delete.png)

Also remove ClusterRoleBinding following steps in the following picture.

![assets/crb-delete.png](assets/crb-delete.png)


Now continue with the [Post removal steps](#post-removal-steps-%EF%B8%8F).

## Post removal steps ➡️

On ROKS, you may want to revert the actions of node labeling for DB2 "no root squash" from https://www.ibm.com/docs/en/db2/11.5?topic=SSEPGG_11.5.0/com.ibm.db2.luw.db2u_openshift.doc/aese-cfg-nfs-filegold.html

During deployment various CustomResourceDefinitions were created, you may want to remove them.

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
