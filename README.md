# Installation of Cloud Pak for Business Automation on containers - One-shot enterprise deployment 🔫

Goal of this repository is to almost automagically install CP4BA Enterprise patterns with all kinds of prerequisites and extras. 

Last installation was performed on 2021-09-20 with CP4BA version 21.0.2-IF003 (also called 21.0.2.3 or 21.2.3)

Deploying CP4BA is based on official documentation which is located at https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=kubernetes-installing-enterprise-deployments.

Deployment of other parts is also based on respective official documentations.

## Disclaimer ✋

This is **not** an official IBM documentation.  
Absolutely no warranties, no support, no responsibility for anything.  
Use it on your own risk and always follow the official IBM documentations.

Please do not hesitate to create an issue here if needed. Your feedback is appreciated.

Not for production use. Suitable for Demo and PoC environments - but with enterprise deployment.  

## Benefits 🚀

- Automatic deployment of the whole platform where you don't need to take care about almost any prerequisites
- Common Global CA used to sign all certificates so there is only one certificate you need to trust in you local machine to trust all URLs of the whole platform
- Trusted certificate in browser also enable you to save passwords
- Wherever possible a common admin user *cpadmin* with adjustable password is used so you don't need to remember multiple credentials when you want to access the platform (convenience also comes with responsibility - so you don't want to expose your platform to whole world)
- The whole platform is running on containers so you don't need to manually prepare anything on traditional VMs and take care of them including required prerequisites
- Many otherwise manual post-deployment steps have been automated
- Pre integrated and automatically connected extras are deployed in the platform for easier access/management/troubleshooting
- You have a working starting Enterprise deployment which you can use as a reference for further custom deployments

## General Information 📢

Result of this Enterprise deployment is not fully supported:
- For convenience, it contains OpenLDAP as a directory provider which is not supported - in real deployments this needs to be replaced with a supported directory provider
- For convenience and lower resource consumption, it uses one containerized DB2 database and schemas for majority of required DBs - in real deployments a supported DB option described on "[Compatibility matrix](https://www.ibm.com/software/reports/compatibility/clarity-reports/report/html/softwareReqsForProduct?deliverableId=F883F7E084D911EB986DCF4EEFB38D3F&osPlatforms=Linux|Mac%20OS|Windows&duComponentIds=D010|D009|D011|S013|S012|S002|S003|C020|C025|C014|C029|C018|C022|C026|C017|C028|C023|C021|C027|C019|C024|C015|C016|C001&mandatoryCapIds=71|26&optionalCapIds=134|62|127|9|401|132|20|161) > Supported Software > Databases" would be used

What is not included:
- IER - cannot use UMS, missing IER object stores and configuration.
- ICCs - cannot use UMS, not covered.
- Caution! FNCM External share - login issues, do not configure, otherwise other capabilities will break as well - waiting for fixes here.
- Workflow Server and Workstream Services - this is a dev deployment. BAW Authoring and (BAW + IAWS) are mutually exclusive in single project.

Keep in mind that the platform contains DB2 which is licensed with Standard Edition license available from CP4BA and it must adhere to the *Additional IBM DB2 Standard Edition Detail* in official license information at http://www-03.ibm.com/software/sla/sladb.nsf/doclookup/F2925E0D5C24EAB4852586FE0060B3CC?OpenDocument (or its newer revision).

Keep in mind that this deployment contains capabilities (the ones which are not bundled with CP4BA) which are not eligible to run on Worker Nodes covered by CP4BA OCP Restricted licenses. More info on https://www.ibm.com/docs/en/cloud-paks/1.0?topic=clusters-restricted-openshift-entitlement.

## Environments used for installation 💻

**Do not run this guide on OpenShift 4.8.x** as DB2 container won't start on it.

ROSA - Red Hat OpenShift Service on AWS doesn't work due to passthrough Routes malfunction.

With proper sizing of the cluster and provided RWX Storage Class, this guide should be working on any OpenShift, however it was successfully executed on the following once.

- ROKS - RedHat OpenShift Kubernetes Service allowing to run managed Red Hat OpenShift on IBM Cloud  
OpenShift 4.7.x - 7 Worker Nodes (16 CPU, 32GB Memory) - ibmc-file-gold-gid Storage Class

- ARO - Azure Red Hat OpenShift allowing to run managed Red Hat OpenShift on Azure 
OpenShift 4.7.x - 7 Worker Nodes (16 CPU, 32GB Memory) - ODF (OCS) with ocs-storagecluster-cephfs Strorage Class

- Traditional OpenShift cluster created from scratch on top of virtualization platform  
OpenShift 4.7.x on vms - 6 Worker Nodes (16 CPU, 32GB Memory) - Managed NFS Storage Class

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
  
### CP4BA (Cloud Pak for Business Automation) section

#### CP4BA capabilities

Purple color is used for CP4BA capabilities.

More info for these capabilities is available in official docs at https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x.

More specifically in overview of patterns at https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-enterprise-deployments.

#### IAF (IBM Automation Foundation) capabilities

Pink color is used for IAF capabilities.

More info for these capabilities is available in official docs at https://www.ibm.com/docs/en/cloud-paks/1.0?topic=automation-foundation.

### CPFS (Cloud Pak Foundational Services) section

Contains services which are reused by Cloud Paks.

More info available in official docs at https://www.ibm.com/support/knowledgecenter/en/SSHKN6/kc_welcome_cs.html.

- Monitoring - Contains Grafana instance for custom dashboarding.
- License metering - Tracks license usage. License Reporter as Web UI is also installed.
- IAM - Provides Identity and Access management.
- Health Checking - Enables you to generate MusthGather output which is useful for support.

### Pre-requisites section

Contains prerequisites for the whole platform.

- DB2 - Database storage for Capabilities which need it.
- OpenLDAP - Directory solution for users and groups definition.
- MSSQL server - Database storage for RPA server.

### Deployment job section

Multiple command line tools are installed inside a container to make the installation possible.

- JDK9 - Used for keytool command to generate certificates for ODM and for Maven (https://manpages.debian.org/unstable/openjdk-8-jre-headless/keytool.1.en.html https://openjdk.java.net/).
- jq - Needed for JSON files manipulation from command line (https://stedolan.github.io/jq/manual/).
- yq - Needed for YAML files manipulation from command line; version 3 is used (https://mikefarah.gitbook.io/yq/).
- oc - Used to communicate with OpenShift from command line (https://docs.openshift.com/container-platform/4.7/cli_reference/openshift_cli/getting-started-cli.html#cli-using-cli_cli-developer-commands).
- Global CA - Generated self-signed Certification Authority via OpenSSL to make trusting the platform easier. It is also possible to provide your own CA and how to do so is described later in this doc.
- helm - Used for helm charts installation (https://helm.sh/docs/).
- maven - Used for pushing ADS library jars to Nexus (https://maven.apache.org/). This enables custom ADS JARs development.

## Pre-requisites ⬅️

- OpenShift cluster sized according with the system requirements
  - Cloud Pak: https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=installation-system-requirements
  - Process Mining: https://www.ibm.com/docs/en/cloud-paks/1.0?topic=platform-pre-installation-requirements
  - RPA: https://www.ibm.com/docs/en/cloud-paks/1.0?topic=automation-pre-installation-requirements
- OpenShift cluster admin access
- Software entitlement key for IBM software which is found at https://myibm.ibm.com/products-services/containerlibrary

## Installation steps ⚡

The following steps instructs you to create new OpenShift resources via YAML files.

You can apply them via OpenShift console (with the handy *plus* icon at the top right - Import YAML) or *oc* CLI from your machine.

![assets/installation-steps.png](assets/installation-steps.png)

### 1. Create new Project

At first, create new *automagic* Project by applying the following yaml (also see the picture below the YAML).

This Project is used to house other resources needed for the One-shot deployment.

```yaml
kind: Project
apiVersion: project.openshift.io/v1
metadata:
  name: automagic
```

![assets/project.png](assets/project.png)

### 2. Assign permissions

This requires the logged in OpenShift user to be cluster admin.

Now you need to assign cluster admin permissions to *automagic* default ServiceAccount under which the installation is performed by applying the following yaml (also see the picture below the YAML).

The ServiceAccount needs to have cluster admin to be able to create all resources needed to deploy the platform.

```yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cluster-admin-automagic
subjects:
  - kind: User
    apiGroup: rbac.authorization.k8s.io
    name: "system:serviceaccount:automagic:default"
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
```

![assets/cluster-role-binding.png](assets/cluster-role-binding.png)

### 3. Add configuration

The installation process needs configuration information properly adjusted to your environment.

Copy the contents of the following yaml to OpenShift console *Import YAML* dialog (as seen in the picture below - point 1 and 2).

Update variables in *variables.sh* entry as wanted (as seen in the picture below - point 2, row starting with *variables.sh*). Keys are divided into sections and every key is documented for you to understand what to fill in it.

You can also choose not to deploy the whole platform by setting various feature variables to *false*.  

Optionally add your custom global CA files if you set *GLOBAL_CA_PROVIDED* variable to *true* (as seen in the picture below - point 3, rows starting with *global-ca.crt* and *global-ca.key*). Make sure the contents of CA files are properly indented to the same level like example contents.

Apply the updated contents to your cluster (as seen in the picture below point 4).

<details open>
  <summary>Click this text to hide / show the configuration YAML file</summary>

<p>

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: automagic
  namespace: automagic
data:
  variables.sh: |
    # Always set these parameters to your values #

    ## Entitlement key from the IBM Container software library. 
    ## (https://myibm.ibm.com/products-services/containerlibrary)  
    ICR_PASSWORD=TODO_ICR_PASSWORD

    ## Name of the OCP storage class used for all PVCs. 
    ## Must be RWX and Fast. Some pillars don't allow to specify storage class, 
    ## so this one will also be automatically set as Default 
    ## For ROKS this class could be ibmc-file-gold-gid
    ## For NFS based class this could be managed-nfs-storage
    ## For ODF (OCS) based class (e.g. on ARO or ROSA) this could be ocs-storagecluster-cephfs    
    STORAGE_CLASS_NAME=ibmc-file-gold-gid

    ## Options are OCP and ROKS
    ## OCP option also applies to other managed OpenShifts
    DEPLOYMENT_PLATFORM=ROKS

    ## By default false, which means that new self signed CA will be generated 
    ## and all certificates will be signed using it. 
    ## Set true if you want to provide your own global-ca.key and global-ca.crt.
    ## Contents of these two files are provided in this ConfigMap in keys which are at the bottom of this file
    ## Files cannot be password protected.
    GLOBAL_CA_PROVIDED=false

    ## In the Platform, multiple users and keystores and other encrypted entries need a password.
    ## To make working with the Platform easier all places which require a password share the same one from this variable.
    ## Make this password strong to ensure that no one from the outside world can login to your Platform.
    ## Password must be alphanumeric (upper and lower case; no special characters allowed).
    UNIVERSAL_PASSWORD=Passw0rd


    # Always review these parameters for changes

    ## Set to false if you don't want to install (or remove) Process Mining
    PM_ENABLED=true

    ## Set to false if you don't want to install (or remove) Asset Repo
    ASSET_REPO_ENABLED=true

    ## Set to false if you don't want to install (or remove) RPA
    RPA_ENABLED=true

    ## Set to false if you don't want to install (or remove) AKHQ
    AKHQ_ENABLED=true

    ## Set to false if you don't want to install (or remove) Cerebro
    CEREBRO_ENABLED=true

    ## Set to false if you don't want to install (or remove) DB2 Management Console
    DB2MC_ENABLED=true

    ## Set to false if you don't want to install (or remove) Roundcube
    ROUNDCUBE_ENABLED=true


    # Update these parameters if needed #

    ## Default attempts used when calling waiting scripts. 
    ## Means wait for 20 minutes with combination of DEFAULT_DELAY. 
    ## Increase if you OCP is slow and you need to wait for things longer.
    DEFAULT_ATTEMPTS=80

    ## Default attempts used when calling waiting scripts. 
    ## Means wait for 20 minutes with combination of DEFAULT_ATTEMPTS. 
    ## Increase if you OCP is slow and you need to wait for things longer.
    DEFAULT_DELAY=15

    ## Used e.g. for DB2. Default attempts used when calling waiting scripts. 
    ## Means wait for 20 minutes with combination of DEFAULT_DELAY_1. 
    ## Increase if you OCP is slow and you need to wait for things longer.
    DEFAULT_ATTEMPTS_1=40

    ## Used e.g. for DB2. Default delay used when calling waiting scripts. 
    ## Means wait for 20 minutes with combination of DEFAULT_ATTEMPTS_1. 
    ## Increase if you OCP is slow and you need to wait for things longer.
    DEFAULT_DELAY_1=30

    ## Used e.g. for CPFS. Default attempts used when calling waiting scripts. 
    ## Means wait for 30 minutes with combination of DEFAULT_DELAY_2. 
    ## Increase if you OCP is slow and you need to wait for things longer.
    DEFAULT_ATTEMPTS_2=30

    ## Used e.g. for CPFS. Default attempts used when calling waiting scripts. 
    ## Means wait for 30 minutes with combination of DEFAULT_ATTEMPTS_2. 
    ## Increase if you OCP is slow and you need to wait for things longer.
    DEFAULT_DELAY_2=60

    ## Used e.g. for CP4BA pillars. Default attempts used when calling waiting scripts. 
    ## Means wait for 60 minutes with combination of DEFAULT_DELAY_3. 
    ## Increase if you OCP is slow and you need to wait for things longer.
    DEFAULT_ATTEMPTS_3=30

    ## Used e.g. for CPFS. Default attempts used when calling waiting scripts. 
    ## Means wait for 60 minutes with combination of DEFAULT_ATTEMPTS_3. 
    ## Increase if you OCP is slow and you need to wait for things longer.
    DEFAULT_DELAY_3=120

    ## Used e.g. for CP4BA pillars. Default attempts used when calling waiting scripts. 
    ## Means wait for 180 minutes with combination of DEFAULT_DELAY_4. 
    ## Increase if you OCP is slow and you need to wait for things longer.
    DEFAULT_ATTEMPTS_4=36

    ## Used e.g. for CPFS. Default attempts used when calling waiting scripts. 
    ## Means wait for 180 minutes with combination of DEFAULT_ATTEMPTS_4. 
    ## Increase if you OCP is slow and you need to wait for things longer.
    DEFAULT_DELAY_4=300

    ## Do NOT enable now. Set to true if you want to use FNCM External Share with Google ID. 
    ## You then need to provide also the following parameters (GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET). 
    ## Video on how to get these values is in assets/fncm-es-google-oidc-pre.mp4
    EXTERNAL_SHARE_GOOGLE=false
    GOOGLE_CLIENT_ID=TODO_GOOGLE_CLIENT_ID
    GOOGLE_CLIENT_SECRET=TODO_GOOGLE_CLIENT_SECRET


    # Touch these parameters only if you know what you are doing! #

    ## Should not be changed in particular guide version. 
    ## Version of Cloud Pak e.g. 20.0.2.1, 20.0.3
    CP4BA_VERSION=21.0.2 
    ## Should not be changed in particular guide version. 
    ## Version of Cloud Pak CASE archive as found on 
    ## https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cp-automation e.g. 3.0.1
    CP4BA_CASE_VERSION=3.1.3
    ## Should not be changed in particular guide version. 
    ## Version of cert-kubernetes folder from Cloud Pak CASE archive e.g. 21.0.1
    CP4BA_CASE_CERT_K8S_VERSION=21.0.2
    ## Should not be changed in particular guide version. 
    ## Version of the Subscription channel as defined on 
    ## https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=cluster-setting-up-by-installing-operator-catalog
    OPERATOR_UPDATE_CHANNEL=v21.2
    ## Hostname of server where DB2 is running
    DB2_HOSTNAME=c-db2ucluster-db2u.db2
    ## Hostname of server where MSSQL is running
    MSSQL_HOSTNAME=mssql.mssql
    ## Name of OCP CP4BA project
    PROJECT_NAME=cp4ba
    ## Name of the CP4BA instance in cr.yaml at path metadata.name
    CR_META_NAME=cp4ba
    ## Hostname of server where LDAP is running
    LDAP_HOSTNAME=openldap-openldap-stack-ha.openldap
    ## Hostname of server where SMTP is running
    MAIL_HOSTNAME=mailserver.mail
    ## OCP API endpoint used for oc login command in --server parameter.
    ## E.g. something like https://api.[ocp_hostname]:6443 for OCP 
    ## and https://[endpoint_part].jp-tok.containers.cloud.ibm.com:[port] for ROKS
    OCP_API_ENDPOINT=TODO_OCP_API_ENDPOINT
    ## Provide either OCP_CLUSTER_ADMIN + OCP_CLUSTER_ADMIN_PASSWORD 
    ## or OCP_CLUSTER_TOKEN (e.g. for ROKS)
    ## Cluster admin of OCP username used for 
    ## oc login command in --username paremeter.
    OCP_CLUSTER_ADMIN=TODO_OCP_CLUSTER_ADMIN_USERNAME
    ## Cluster admin of OCP password used for 
    ## oc login command in --password paremeter.
    OCP_CLUSTER_ADMIN_PASSWORD=TODO_OCP_CLUSTER_ADMIN_PASSWORD
    ## Login token of Cluster admin of OCP (useful for ROKS) used for 
    ## oc login command in --token paremeter. 
    ## Replace this value before every interaction to make sure your token is valid long enough.
    OCP_CLUSTER_TOKEN=TODO_OCP_CLUSTER_ADMIN_TOKEN

  global-ca.crt: |
    -----BEGIN CERTIFICATE-----
    TODO_YOUR_BASE64_CONTENT
    -----END CERTIFICATE-----

  global-ca.key: |
    -----BEGIN RSA PRIVATE KEY-----
    TODO_YOUR_BASE64_CONTENT
    -----END RSA PRIVATE KEY-----

```

</p>
</details>

![assets/config-map-variables.png](assets/config-map-variables.png)

![assets/config-map-tls.png](assets/config-map-tls.png)

### 4. Run the Job

Trigger the installation by applying the following YAML (also see the picture below the YAML).

This Job runs a Pod which performs the installation.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  generateName: automagic-intall-
  namespace: automagic
spec:
  template:
    metadata:
      labels:
        app: automagic  
    spec:
      containers:
        - name: automagic
          image: ubi8/ubi
          command: ["/bin/bash"]
          args:
            ["-c","cd /usr; curl -kL -o cp4ba.tgz ${GIT_ARCHIVE}; tar xvf cp4ba.tgz; DIR=`find . -name \"apollo*\"`; cd ${DIR}/scripts; chmod u+x automagic.sh; ./automagic.sh"]
          imagePullPolicy: IfNotPresent
          env:
            - name: ACTION
              value: install
            - name: GIT_ARCHIVE
              value: https://github.com/apollo-business-automation/ibm-cp4ba-enterprise-deployment/tarball/main
            - name: CONTAINER_RUN_MODE
              value: "true"
          volumeMounts:
            - name: config
              mountPath: /config/
      restartPolicy: Never
      volumes:
        - name: config
          configMap:
            name: automagic
  backoffLimit: 0
```

![assets/install-job.png](assets/install-job.png)

Now you need to wait for a couple of hours 6-10 for the installation to complete depending on speed of your OpenShift and StorageClass bounding.

You can watch progress in log of Pod which was created by the Job and its name starts with *automagic-install-*. See below images to find the logs.

During execution, printed Timestamps are in UTC.

Find the pod of install Job.

![assets/install-job-pod.png](assets/install-job-pod.png)

Then open logs tab.

![assets/install-job-pod-log.png](assets/install-job-pod-log.png)

#### Successful completion

Successful completion is determined by seeing that the Job is *Complete* (in the below picture point 1) and the pod is also *Completed* (in the below picture point 3).

![assets/success-install-job-pod.png](assets/success-install-job-pod.png)

Also the pod log ends with "CP4BA Enterprise install completed"  (in the below picture point 1).  

![assets/success-install-job-log.png](assets/success-install-job-log.png)

Now continue with the [Post installation steps](#post-installation-steps-%EF%B8%8F) and then review [Usage & Operations](#usage--operations-).

#### Failed completion

If something goes wrong, the Job is *Failed* (in the below picture point 1) and the pod has status *Error* (in the below picture point 3).

![assets/failed-install-job-pod.png](assets/failed-install-job-pod.png)

Also the pod log ends with message ending with the word "Failed" (in the below picture point 1).

![assets/failed-install-job-log.png](assets/failed-install-job-log.png)

Further execution is stopped - and you need to troubleshoot why the installation failed, fix your environment, clean the cluster by following [Removal steps](#removal-steps-%EF%B8%8F) and after successful removal retry installation from step [4. Run the Job](#4-run-the-job).

## Post installation steps ➡️

Review and perform post deploy manual steps for CP4BA as specified in ConfigMap *cp4ba-postdeploy* in *postdeploy.md* file. See below images to find this file. It is best to copy the contents and open it in nice MarkDown editor like VSCode. 

![assets/cp4ba-postdeploy-cm.png](assets/cp4ba-postdeploy-cm.png)

![assets/cp4ba-postdeploy-md.png](assets/cp4ba-postdeploy-md.png)


Review and perform post deploy manual steps for RPA as specified in ConfigMap *rpa-postdeploy.md* in *postdeploy.md* file. See below images to find this file. It is best to copy the contents and open it in nice MarkDown editor like VSCode.

![assets/rpa-postdeploy-cm.png](assets/rpa-postdeploy-cm.png)

![assets/rpa-postdeploy-md.png](assets/rpa-postdeploy-md.png)

## Usage & Operations 😊

Endpoints, access info and other useful information is available in Project *automagic* in ConfigMap named *usage* in *usage.md* file after installation. It is best to copy the contents and open it in nice MarkDown editor like VSCode.

![assets/usage-cm.png](assets/usage-cm.png)

![assets/usage-md.png](assets/usage-md.png)

## Removal steps 🗑️

Useful when you want to clean up your environment.

You can use it even if the deployment failed and everything was not deployed but expect to see some failures as script tries to remove things which doesn't exist. You can ignore such errors.

### 1. Run the Job

Trigger the removal by applying the following YAML (also see the picture below the YAML).

This Job runs a Pod which performs the removal.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  generateName: automagic-remove-
  namespace: automagic
spec:
  template:
    metadata:
      labels:
        app: automagic  
    spec:
      containers:
        - name: automagic
          image: ubi8/ubi
          command: ["/bin/bash"]
          args:
            ["-c","cd /usr; curl -kL -o cp4ba.tgz ${GIT_ARCHIVE}; tar xvf cp4ba.tgz; DIR=`find . -name \"apollo*\"`; cd ${DIR}/scripts; chmod u+x automagic.sh; ./automagic.sh"]
          imagePullPolicy: IfNotPresent
          env:
            - name: ACTION
              value: remove
            - name: GIT_ARCHIVE
              value: https://github.com/apollo-business-automation/ibm-cp4ba-enterprise-deployment/tarball/main
            - name: CONTAINER_RUN_MODE
              value: "true"
          volumeMounts:
            - name: config
              mountPath: /config/
      restartPolicy: Never
      volumes:
        - name: config
          configMap:
            name: automagic
  backoffLimit: 0
```

![assets/remove-job.png](assets/remove-job.png)

Now you need to wait for some time (30 minutes to 1 hour) for the removal to complete depending on the speed of your OpenShift.

You can watch progress in log of Pod which was created by the Job and its name starts with *automagic-remove-*. See below images to find the logs.

During execution, printed Timestamps are in UTC.

Find the pod of remove Job.

![assets/remove-job-pod.png](assets/remove-job-pod.png)

Then open logs tab.

![assets/remove-job-pod-log.png](assets/remove-job-pod-log.png)

#### Successful removal

Successful completion of removal is determined by seeing that the Job is *Complete* (in the below picture point 1) and the pod is also *Completed* (in the below picture point 3).

![assets/success-remove-job-pod.png](assets/success-remove-job-pod.png)

Also the pod log ends with "CP4BA Enterprise remove completed" (in the below picture point 1).  

![assets/success-remove-job-log.png](assets/success-remove-job-log.png)

#### Failed removal

If something goes wrong, the Job is *Failed* and the pod has status *Error* (similarly as in failed installation at [Failed completion](#failed-completion).

Also the pod log ends with message ending with the word "Failed".

Further execution is stopped - and you need to troubleshoot why the removal failed, fix your environment and retry removal from step [1. Run the Job](#1-run-the-job).

### 2. Remove automagic Project

If you don't plan to repeat install or removal steps, you can remove whole *automagic* Project following steps in the following picture.

![assets/project-delete.png](assets/project-delete.png)

Now continue with the [Post removal steps](#post-removal-steps-%EF%B8%8F).

## Post removal steps ➡️

StorageClass defined in ConfigMap *automagic* in *variables.sh* in variable *STORAGE_CLASS_NAME* was set as Default, you may want choose some other Default Storage Class.  

On ROKS, you may want to revert the actions of node labeling for DB2 "no root squash" from https://www.ibm.com/docs/en/db2/11.5?topic=requirements-cloud-file-storage

During deployment various CustomResourceDefinitions were created, you may want to remove them.

## Contact

Jan Dušek  
jdusek@cz.ibm.com  
Business Automation Technical Specialist  
IBM
