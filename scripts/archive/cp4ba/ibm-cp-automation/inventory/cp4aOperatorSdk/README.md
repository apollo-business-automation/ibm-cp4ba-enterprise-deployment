# Name

IBM&reg; Cloud Pak for Business Automation

# Introduction

## Summary
Cloud Pak for Business Automation delivers a robust, end-to-end solution for business automation needs within the clients' enterprise. In the current competitive marketplace, digital companies use software automation to achieve higher revenue per employee than their traditional counterparts. Business Automation can maximize revenue per employee by reinventing the client experience while reducing costs.
Cloud Pak for Business Automation platform delivers an integrated and managed collection of containerized or virtualized Automation Platform for Digital Business services thatenable rapid deployment and reduce operational costs. Cloud Pak for Business Automation also digitizes all aspects of business operations and can extend the workforce with digital labor to enable businesses to scale.

## Features

Follow [link](http://www.ibm.com/support/knowledgecenter/SSYHZ8_21.0.x/com.ibm.dba.install/op_topics/con_capab_ent.html) for more details.

* IBM&reg; FileNet Content Manager

  IBM FileNet Content Manager provides enterprise content management to enable secure access, collaboration support, content synchronization and sharing, and mobile  support to engage users over all channels and devices. IBM® FileNet® Content Manager consists of Content Process Engine (CPE), Content Search Service (CSS), Content  Management Interoperability Services (CMIS), Content Navigator Task Manager  and Content Services GraphQL (CGQL).

* IBM&reg; Business Automation Navigator
  
  IBM Business Automation Navigator provides a console to enable teams to view their documents, folders, and searches in ways that help them to complete their tasks.

* IBM&reg; Operational Decision Manager
 
  IBM® Operational Decision Manager automates policies and decisions by managing thousands of business rules and enabling rapid business change.

* IBM&reg; Business Automation Insights
 
  IBM Business Automation Insights is a optional component, provides visualization and insights to knowledge workers and business owners. Business Automation Insig  hts provides dashboarding and data science capabilities from the events and business data collected from Cloud Pak for Automation services.

* IBM&reg; Business Automation Studio

  IBM Business Automation Studio environment for providing a single place where people go to author business services, applications and digital workers.

* IBM&reg; Business Automation Application Engine

  IBM Business Automation Application Engine (App Engine), a user interface service tier to run applications that are built by IBM Business Automation Application Designer (App Designer).
  
* IBM&reg; Business Automation Workflow

  IBM Business Automation Workflow simplifies workflows and helps you easily and collaboratively discover new ways to automate and scale work by combining business process and case management capabilities.

* IBM&reg; User Management Service

  User Management Service provides users of multiple IBM Cloud Pak for Automation components with a single sign-on experience.

* IBM&reg; Automation Decision Services

  Automation Decision Services provides decision modeling capabilities that help business experts capture and automate repeatable decisions

* IBM&reg; IBM Automation Document Processing
  
  IBM Automation Document Processing provides the capabilities that help you build an AI-powered data enrichment tool for document processing and storage

* IBM&reg; IBM Enterprise Records

  Enterprise Records helps you create and maintain accurate, secure, and reliable records for both, electronic and physical information.

* IBM&reg; IBM Content Collector for SAP
  
  IBM Content Collector for SAP is an archiving solution that is designed for Lotus® Domino®, Microsoft Exchange Server, email through SMTP, Microsoft SharePoint, IBM Connections, and Windows file systems.

IBM Cloud Pak for Business Automation provides the means to acquire and apply key software from across the Digital Business Automation portfolio to digitize and automate all aspects of your business operations. IBM Cloud Paks deliver a hybrid cloud platform that enables businesses to use a mix of on-premises, public, and privately-operated cloud environments for your data and applications. See https://www.ibm.com/support/knowledgecenter/en/SSYHZ8_21.0.x/welcome/kc_welcome_dba_distrib.html for more information.

# CASE Details

## Prerequisites

- Redhat Openshift Container Platform version 4.4 and above
- NFS Server or Gluster File System or cloud-specific storage system
- Download  service_account.yaml, role.yaml, role_binding.yaml, operator.yaml.[link](http://www.ibm.com/support/knowledgecenter/SSYHZ8_21.0.x/com.ibm.dba.install/op_topics/con_cp4a_operator.html)
- Download required custom resource definition (CRD) and custom resource (CR) files icp4a_v1_icp4a_crd.yaml, icp4a_v1_icp4a_cr_template.yaml
- Modify custom resource definition file in case you want to change default ICP4A custom resource. [link](http://www.ibm.com/support/knowledgecenter/SSYHZ8_21.0.x/com.ibm.dba.install/op_topics/con_install_templates.html)
- Modify custom resource file to enable which component you want to deploy.
- Create Docker registry secret and provide the secret name in Custom Resource file.
- Create a secret with LDAP password , database user password and provide the secret name in corresponding section of Custom Resource file.
- Cloud Pak for Business Automation Operator requires 2  persistent volume before deployment.
- The following table describes the storage required for Cloud Pak for Automation.
  - Cloud Pak for Business Automation Operator
    - Follow [link]( http://www.ibm.com/support/knowledgecenter/SSYHZ8_21.0.x/com.ibm.dba.install/op_topics/tsk_operators.html) for installation instructions.

      | Persistent Volumes            | Persistent Volume Claims        | Description                     |
      | ---------------------------   | ------------------------------- |  ---------------------------------------------     |
      | `operator-shared-pv`         | `operator-shared-pvc`          | `Database drivers required to deploy Cloud Pak for Business Automation deployment` |
      | `operator-log-pv`            | `operator-log-pvc`             | `Operator ansible logs for Cloud Pak for Business Automation deployment`           |

    * Use the below instructions to create  necessary PersistentVolume and PersistentVolumeClaim or specify storage class name for the storage parameters to dynamically provision required PersistentVolumeClaims.

  - IBM® FileNet Content Manager
    * Follow [link](http://www.ibm.com/support/knowledgecenter/SSYHZ8_21.0.x/com.ibm.dba.install/op_topics/tsk_create_vol_folders_manually.html)
    * Follow [link](http://www.ibm.com/support/knowledgecenter/SSYHZ8_21.0.x/com.ibm.dba.install/op_topics/tsk_plan_storage.html)

  - IBM® Business Automation Studio
    * Follow [link](https://www.ibm.com/support/knowledgecenter/SSYHZ8_21.0.x/com.ibm.dba.install/k8s_topics/tsk_prepare_bas.html) for details about this product.

  - IBM® Operation Decision Manager
    * Follow [link](http://www.ibm.com/support/knowledgecenter/SSYHZ8_21.0.x/com.ibm.dba.offerings/topics/con_odm_prod.html) for details about this product.

  - IBM® Business Automation Application Engine
    * Follow [link](https://www.ibm.com/support/knowledgecenter/SSYHZ8_21.0.x/com.ibm.dba.install/k8s_topics/tsk_prepare_ae.html) for details about this product.

  - IBM® Business Automation Workflow
    * Follow [link](http://www.ibm.com/support/knowledgecenter/SSYHZ8_21.0.x/com.ibm.dba.offerings/topics/con_baw.html) for details about this product.

  - IBM® Automation Decision Services
    * Follow [link](http://www.ibm.com/support/knowledgecenter/SSYHZ8_21.0.x/com.ibm.dba.aid/topics/con_ov_intro.html) for details about this product.

  - IBM® Automation Document Processing
    * Follow [link](http://www.ibm.com/support/knowledgecenter/SSYHZ8_21.0.x/com.ibm.dba.aid/topics/con_ov_intro.html) for details about this product.

  - IBM® Enterprise Records
    * Follow [link](http://www.ibm.com/support/knowledgecenter/SSYHZ8_21.0.x/com.ibm.dba.offerings/topics/con_ier.html) for details about this product.

  - IBM® Content Collector for SAP
    * Follow [link](http://www.ibm.com/support/knowledgecenter/SSYHZ8_21.0.x/com.ibm.dba.offerings/topics/con_ier.html) for details about this product.

# PodSecurityPolicy Requirements

# SecurityContextConstraints Requirements

### Red Hat OpenShift SecurityContextConstraints Requirements
This Operator requires a SecurityContextConstraints to be bound to the target namespace prior to installation. This Operator is namespace scoped so it can deploy into any target namespace and furthermore you can deploy the Operator multiple times using difference namespaces.

  - IBM® Business Automation Workflow
```
Follow [link](http://www.ibm.com/support/knowledgecenter/SSYHZ8_21.0.x/com.ibm.dba.install/op_topics/tsk_bawprep_scc.html)
```
  - IBM® Business Automation Insights
```
Follow [link](http://www.ibm.com/support/knowledgecenter/SSYHZ8_21.0.x/com.ibm.dba.install/op_topics/tsk_preparing_baik8s_security_policy.html)
```
1. For Red Hat OpenShift, add SecurityContextConstraints (SCC) requirements.
If you are installing the chart on Red Hat OpenShift or OKD, the privileged SecurityContextConstraint resource is required for the installation. For more information, see IBM Cloud Pak SecurityContextConstraints Definitions.

2. For RedHat OpenShift, if applicable, add policies to enable the Pod resources to start the containers by using the required UIDs.
To ensure that these containers can start use the oc command to add the service accounts to the required privileged SCC, add these policies.

```
oc adm policy add-scc-to-user privileged -z <cr_name>-bai-psp-sa
oc adm policy add-scc-to-user privileged -z default
```
  - IBM® FileNet Content Manager
For Red Hat OpenShift, the default restricted SecurityContextConstraints (SCC) is sufficient.

  - IBM® Business Automation Navigator
For Red Hat OpenShift, the default restricted SecurityContextConstraints (SCC) is sufficient.

  - IBM® Business Automation Studio
For Red Hat OpenShift, the default restricted SecurityContextConstraints (SCC) is sufficient.

  - IBM® Business Automation Application Engine
For Red Hat OpenShift, the default restricted SecurityContextConstraints (SCC) is sufficient.

  - IBM® Operational Decison Manager
For Red Hat OpenShift, the default restricted SecurityContextConstraints (SCC) is sufficient.

  - IBM® Enterprise Records
For Red Hat OpenShift, the default restricted SecurityContextConstraints (SCC) is sufficient.

  - IBM® User Management Service
For Red Hat OpenShift, the default restricted SecurityContextConstraints (SCC) is sufficient.

### Resources Required

Minimum scheduling capacity:

| Software  | Memory (GB) | CPU (cores) | Disk (GB) | Nodes |
| --------- | ----------- | ----------- | --------- | ----- |
|           |             |             |           |       |
| CP4A      |  32 GB      |    16       |   500     |  5    |


# Download required container images.
- You can access the container images in the IBM Entitled registry with your IBMid (Option 1), or you can use the downloaded archives from IBM Passport Advantage (PPA) (Option 2).

        * Option 1: Create a pull secret for the IBM Cloud Entitled Registry
          - Log in to [MyIBM Container Software Library](https://myibm.ibm.com/products-services/containerlibrary) with the IBMid and password that are associated with the entitled software.
          - In the **Container software library** tile, click **View library** and then click **Copy key** to copy the entitlement key to the clipboard.
          - Create a pull secret by running a `kubectl create secret` command.
             ```bash
             $ kubectl create secret docker-registry <my_pull_secret> --docker-server=cp.icr.io --docker-username=iamapikey --docker-password="<API_KEY_GENERATED>" --docker-email=user@foo.com
             ```
             > **Note**: The `cp.icr.io` value for the **docker-server** parameter is the only registry domain name that contains the images.
          - Take a note of the secret and the server values so that you can set them to the **pullSecrets** and **repository** parameters when you run the operator for your containers.

        * Option 2: Download the packages from PPA and load the images
          [IBM Passport Advantage (PPA)](https://www-01.ibm.com/software/passportadvantage/pao_customer.html) provides archives (.tgz) for the software. To view the list of Passport Advantage eAssembly installation images, refer to the [20.0.1 download document](https://www.ibm.com/support/pages/ibm-cloud-pak-automation-v2001-download-document)
          - Download one or more PPA packages to a server that is connected to your container registry.
          - Download the [`loadimages.sh`](../../scripts/loadimages.sh) script from GitHub.
          - Run the `loadimages.sh` script to load the images into your Docker registry. Specify the two mandatory parameters in the command line.
          ```
          -p  PPA archive files location or archive filename
          -r  Target Docker registry and namespace
          -l  Optional: Target a local registry
          ```

          The following example shows the input values in the command line.

          ```
          # scripts/loadimages.sh -p <PPA-ARCHIVE>.tgz -r docker-registry.default.svc:5000/my-project
          ```

          > **Note**: The project must have pull request privileges to the registry where the images are loaded. The project must also have pull request privileges to push the images into another namespace/project.
          - Check that the images are pushed correctly to the registry.
          ```bash
          $ oc get is --all-namespaces
          ```
          or
          ```bash
          $ oc get is -n my-project

# Installing the CASE

- Apply Custom Resource Definition file -> oc apply -f ibm_cp4a_crd.yaml
- Create a service account -> oc apply -f service_account.yaml
- Create a required role -> oc apply -f role.yaml
- Apply required role binding -> oc apply -f role_binding.yaml
- Deploy CP4A Operator ->  oc apply  -f operator.yaml
- Apply modified Custom Resource for the component which you want to deploy. [link](http://www.ibm.com/support/knowledgecenter/SSYHZ8_21.0.x/com.ibm.dba.install/op_topics/con_install_templates.html) 

For installation instructions, see https://www.ibm.com/support/knowledgecenter/en/SSYHZ8_21.0.x/com.ibm.dba.install/k8s_topics/tsk_install_kubernetes.html

## Configuration

Create a namespace and execute Cloud Pak for Business Automation Operator deployment.

## Storage

IBM® Cloud Pak for Business Automation supports a NFS storage system.  A NFS storage system needs to be created as a pre-req before deploying IBM® Cloud Pak for Business Automation chart. 
Dynamic Provisioning of PersistenceVolumes is not supported by provising Storage Class in Custom Resource file.

## Documentation

## Details
- Knowledge Center link [link](https://www.ibm.com/support/knowledgecenter/en/SSYHZ8_21.0.x/welcome/kc_welcome_dba_distrib.html)

## Limitations
- Known limitations. [link](https://www.ibm.com/support/knowledgecenter/en/SSYHZ8_21.0.x/com.ibm.dba.aid/topics/con_known_limitations.html)
