# Installation of Cloud Pak for Business Automation on containers - One-shot enterprise deployment 🔫

Goal of this repository is to almost automagically install CP4BA Enterprise patterns and also IAF components with all kinds of prerequisites and extras on OpenShift.

Last installation was performed on 2022-01-11 with CP4BA version 21.0.3 (also called 21.0.3 or 21.3.0)

Deploying CP4BA is based on official documentation which is located at https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=overview-what-is-cloud-pak-business-automation.

Deployment of other parts is also based on respective official documentations.

- IBM Robotic Process Automation (RPA) https://www.ibm.com/docs/en/cloud-paks/1.0?topic=automation-planning-rpa-openshift
- IBM Automation Assets https://www.ibm.com/docs/en/cloud-paks/1.0?topic=foundation-automation-assets
- IBM Process Mining https://www.ibm.com/docs/en/cloud-paks/1.0?topic=pm-installation-setup-guide-process-mining-openshift-container-platform
- IBM Automation Foundation (IAF) https://www.ibm.com/docs/en/cloud-paks/1.0?topic=automation-foundation
- IBM Cloud Pak Foundational Services (CPFS) https://www.ibm.com/docs/en/cpfs?topic=operator-installing-foundational-services-online

## Disclaimer ✋

This is **not** an official IBM documentation.  
Absolutely no warranties, no support, no responsibility for anything.  
Use it on your own risk and always follow the official IBM documentations.  
It is always your responsibility to make sure you are license compliant when using this repository to install IBM Cloud Pak for Business Automation.

Please do not hesitate to create an issue here if needed. Your feedback is appreciated.

Not for production use. Suitable for Demo and PoC environments - but with enterprise deployment.  

**!Important** - Keep in mind that the platform contains DB2 which is licensed with Standard Edition license available from CP4BA and it must adhere to the *Additional IBM DB2 Standard Edition Detail* in official license information at http://www-03.ibm.com/software/sla/sladb.nsf/doclookup/F2925E0D5C24EAB4852586FE0060B3CC?OpenDocument (or its newer revision).

**!Important** - Keep in mind that this deployment contains capabilities (the ones which are not bundled with CP4BA) which are not eligible to run on Worker Nodes covered by CP4BA OCP Restricted licenses. More info on https://www.ibm.com/docs/en/cloud-paks/1.0?topic=clusters-restricted-openshift-entitlement.

**!Important** - Keep in mind that this deployment contains *IBM Daeja ViewONE Virtual Module for Microsoft Office* and *IBM Daeja ViewONE Virtual Module for Permanent Redaction* enabled which require additional licenses as per official license information at http://www-03.ibm.com/software/sla/sladb.nsf/doclookup/F2925E0D5C24EAB4852586FE0060B3CC?OpenDocument (or its newer revision).

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
- IER - missing IER object stores and configuration.
- ICCs - not covered.
- Caution! FNCM External share - login issues, do not configure, otherwise other capabilities will break as well - waiting for fixes.
- Caution! RPA currently works only with one user cpadmin due to identity issue.
- Caution! Process MIning currently doesn't work - IAF operator issues, BAI integration issues - waiting for fixes.
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
- Mongo Express - Web UI for MOngo DB databases for CP4BA and Process Mining to easier troubleshoot DB.
  
### CP4BA (Cloud Pak for Business Automation) section

#### CP4BA capabilities

Purple color is used for CP4BA capabilities.

More info for these capabilities is available in official docs at https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3.

More specifically in overview of patterns at https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=deployment-capabilities-production-deployments.

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

- JDK9 - Used for keytool command to generate certificates for ODM and for Maven (https://docs.oracle.com/javase/8/docs/technotes/tools/unix/keytool.html https://openjdk.java.net/).
- jq - Needed for JSON files manipulation from command line (https://stedolan.github.io/jq/manual/).
- yq - Needed for YAML files manipulation from command line; version 3 is used (https://mikefarah.gitbook.io/yq/).
- oc - Used to communicate with OpenShift from command line (https://docs.openshift.com/container-platform/4.8/cli_reference/openshift_cli/getting-started-cli.html#cli-using-cli_cli-developer-commands).
- Global CA - Generated self-signed Certification Authority via OpenSSL to make trusting the platform easier. It is also possible to provide your own CA and how to do so is described later in this doc.
- helm - Used for helm charts installation (https://helm.sh/docs/).
- maven - Used for pushing ADS library jars to Nexus (https://maven.apache.org/). This enables custom ADS JARs development.

## Environments used for installation 💻

With proper sizing of the cluster and provided RWX Storage Class, this guide should be working on any OpenShift 4.8, however it was executed on the following once.

- ROKS - RedHat OpenShift Kubernetes Service allowing to run managed Red Hat OpenShift on IBM Cloud  
OpenShift 4.8.x - 7 Worker Nodes (16 CPU, 32GB Memory) - ibmc-file-gold-gid Storage Class  
Successfully installed

- ARO - Azure Red Hat OpenShift allowing to run managed Red Hat OpenShift on Azure  
OpenShift 4.8.x - 7 Worker Nodes (16 CPU, 32GB Memory) - ODF (OCS) with ocs-storagecluster-cephfs Strorage Class  
Successfully installed

- Traditional OpenShift cluster created from scratch on top of virtualization platform  
OpenShift 4.8.x on vms - 7 Worker Nodes (16 CPU, 32GB Memory) - Managed NFS Storage Class  
Successfully installed

- ROSA - Red Hat OpenShift Service on AWS  
OpenShift 4.8.x - 7 Worker Nodes (16 CPU, 32GB Memory) - ODF (OCS) with ocs-storagecluster-cephfs Strorage Class  
Successfully installed **but has issues** with passthrough Routes malfunction making it hard to access the platform.

The following picture shows real idle utilization of Nodes with deployed platform on above mentioned ROKS as an example.

![assets/utilization.png](assets/utilization.png)

The following output shows CPU and Memory requests and limits on Nodes on above mentioned ROKS as an example.

```text
node/10.162.243.89
  Resource           Requests          Limits
  cpu                9346m (58%)       24270m (152%)
  memory             19965459Ki (68%)  41767200Ki (144%)

node/10.163.57.136
  Resource           Requests          Limits
  cpu                10234m (64%)      22850m (143%)
  memory             18918931Ki (65%)  33315104Ki (114%)

node/10.163.57.150
  Resource           Requests          Limits
  cpu                9096m (57%)       18400m (115%)
  memory             18354707Ki (63%)  33843488Ki (116%)

node/10.163.57.152
  Resource           Requests          Limits
  cpu                10078m (63%)      23040m (145%)
  memory             20524563Ki (70%)  44028192Ki (151%)

node/10.163.57.155
  Resource           Requests          Limits
  cpu                4948m (31%)       4600m (28%)
  memory             26953235Ki (93%)  25973024Ki (89%)

node/10.163.57.231
  Resource           Requests          Limits
  cpu                11600m (73%)      18500m (116%)
  memory             22577683Ki (77%)  28880160Ki (99%)  
```

## Pre-requisites ⬅️

- OpenShift cluster sized according with the system requirements
  - Cloud Pak: https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.3?topic=ppd-system-requirements
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
    ## Contents of these two files are provided in this ConfigMap in keys which are at the bottom of this file.
    ## Files cannot be password protected.
    GLOBAL_CA_PROVIDED=false

    ## In the Platform, multiple users and keystores and other encrypted entries need a password.
    ## To make working with the Platform easier all places which require a password share the same one from this variable.
    ## Make this password strong to ensure that no one from the outside world can login to your Platform.
    ## Password must be alphanumeric (upper and lower case; no special characters allowed).
    UNIVERSAL_PASSWORD=Passw0rd


    # Always review these parameters for changes

    ## Do NOT enable now!
    ## Set to false if you don't want to install (or remove) Process Mining
    PM_ENABLED=false

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

    ## Do NOT enable now. Set to true if you want to use FNCM External Share with Google ID. 
    ## You then need to provide also the following parameters (GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET). 
    ## Video on how to get these values is in assets/fncm-es-google-oidc-pre.mp4
    EXTERNAL_SHARE_GOOGLE=false
    GOOGLE_CLIENT_ID=TODO_GOOGLE_CLIENT_ID
    GOOGLE_CLIENT_SECRET=TODO_GOOGLE_CLIENT_SECRET

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
  generateName: automagic-install-
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

Specifically, if you haven't provided your own Global CA, review the section *Global CA* in this md file.

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

On ROKS, you may want to revert the actions of node labeling for DB2 "no root squash" from https://www.ibm.com/docs/en/db2/11.5?topic=SSEPGG_11.5.0/com.ibm.db2.luw.db2u_openshift.doc/aese-cfg-nfs-filegold.html

During deployment various CustomResourceDefinitions were created, you may want to remove them.

## Contact

Jan Dušek  
jdusek@cz.ibm.com  
Business Automation Technical Specialist  
IBM Czech Republic

## Notice

© Copyright IBM Corporation 2021.
