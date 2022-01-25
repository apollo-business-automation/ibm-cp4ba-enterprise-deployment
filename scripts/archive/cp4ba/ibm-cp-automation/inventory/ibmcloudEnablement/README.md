# Name

IBM Cloud Pak&reg; for Business Automation

# Introduction

## Summary
IBM Cloud Pak for Business Automation is a modular set of integrated software, built for any hybrid cloud, that quickly solves your toughest operational challenges. It includes the broadest set of AI-powered automation capabilities in the market – content, capture, decisions, workflows, and tasks – with a flexible model that lets you start small and scale up as your needs evolve. Get started with RPA to free up human employees, speed decisioning with operational intelligence, and expand to automate key types of work across core operations. All of which can be tailored to integrate with your existing investments. With actionable AI-generated recommendations, built-in analytics to measure impact, and business-friendly tooling to speed innovation, our software has helped clients reduce process completion times by 90% [1], decrease customer wait times by half [2]  and save thousands of work hours that were then reallocated to higher value work [3].

## Features

Follow [link](http://www.ibm.com/support/knowledgecenter/SSYHZ8_21.0.x/com.ibm.dba.install/op_topics/con_caps.html) for more details.

* IBM FileNet&reg; Content Manager

  IBM FileNet Content Manager provides enterprise content management to enable secure access, collaboration support, content synchronization and sharing, and mobile  support to engage users over all channels and devices. IBM FileNet Content Manager consists of Content Process Engine (CPE), Content Search Service (CSS), Content  Management Interoperability Services (CMIS), Content Navigator Task Manager  and Content Services GraphQL (CGQL).

* IBM Business Automation Navigator
  
  IBM Business Automation Navigator provides a console to enable teams to view their documents, folders, and searches in ways that help them to complete their tasks.

* IBM Operational Decision Manager
 
  IBM Operational Decision Manager automates policies and decisions by managing thousands of business rules and enabling rapid business change.

* IBM Business Automation Studio

  IBM Business Automation Studio environment for providing a single place where people go to author business services, applications and digital workers.

* IBM Business Automation Application Engine

  IBM Business Automation Application Engine (App Engine), a user interface service tier to run applications that are built by IBM Business Automation Application Designer (App Designer).
  
* IBM Automation Workstream Services and Business Automation Workflow

  IBM Business Automation Workflow simplifies workflows and helps you easily and collaboratively discover new ways to automate and scale work by combining business process and case management capabilities.

* IBM User Management Service

  User Management Service provides users of multiple IBM Cloud Pak for Automation components with a single sign-on experience.

* IBM Automation Decision Services

  Automation Decision Services provides decision modeling capabilities that help business experts capture and automate repeatable decisions

* IBM Automation Document Processing
  
  IBM Automation Document Processing provides the capabilities that help you build an AI-powered data enrichment tool for document processing and storage

IBM Cloud Pak for Business Automation provides the means to acquire and apply key software from across the Digital Business Automation portfolio to digitize and automate all aspects of your business operations. IBM Cloud Paks deliver a hybrid cloud platform that enables businesses to use a mix of on-premises, public, and privately-operated cloud environments for your data and applications. See https://www.ibm.com/support/knowledgecenter/SSYHZ8_21.0.x/welcome/kc_welcome_dba_distrib.html for more information.

# Prerequisites
In order to deploy this Cloud Pak, you must already have a valid license to the Cloud Pak. If your organization has already purchased a valid license, your account administrator needs to bind the entitlement to your IBM Cloud account before you will be able to assign an entitlement using the create tab. If your organization has not yet purchased a license to the Cloud Pak, contact your IBM sales representative.
Installation of Cloud Pak for Business Automation on IBM Cloud using the IBM software catalog does not support multi-zone (MZR) clusters.

# Resources Required

Minimum scheduling capacity:

| Software  | Memory (GB) | CPU (cores) | Disk (GB) | Nodes |
| --------- | ----------- | ----------- | --------- | ----- |
| CP4A      |  32 GB      |    16       |   500     |  5    |


# Accessing Container Images
- You can access the container images in the IBM Entitled registry with your IBMid.

# Installing

- Create a ROKS 4.6+ cluster.
- Use an existing project or provide a name to create one.
- Click on Run Script which prepares the namespace to install.
- Click on Set Deployment Values to choose a capability to install.
- Choose the Capability or Capabilities from the list.
- Accept the License Agreement.
- Click Install to launch the Schematics Workspace to monitor the installation log.

# Post Installation steps for Automation Document Processing (ADP) for GPU-enabled Openshift Cluster


- If your OpenShift cluster has GPU-enabled worker nodes, you can configure Automation Document Processing (ADP) to make use of the GPU to improve performance. Here are the additional steps you need to perform after your deployment is complete:

* Prerequisite:
  In order to configure ADP to use GPU, you need to know the node label for your GPU-enabled nodes.

  You can see the node labels in the OpenShift console (Compute -> Nodes -> select a worker node -> Details) or from the OpenShift commandline with the command 
  `oc get nodes --show-labels`

* To configure the Automation Document Processing to use GPU, you can use the OpenShift console or commandline.

  If you prefer to use the Openshift console, use these steps:

  1. Login to your Openshift console as a user with admin privileges.

  2. Navigate to Operators -> Installed Operators

  3. From the list of Installed Operators, select IBM Cloud Pak for Business Automation

  4. Navigate to the "CP4BA deployment" tab. Select "icp4adeploy" from the list.

  5. Navigate to the "YAML" tab.

  6. Inside the editor, scroll down to a position under the "spec:" section.

  7. Add the following (replace the values for "yourkey" and "yourvalue" based on your node label):
  
```ca_configuration:
     deeplearning:
      gpu_enabled: true
      nodelabel_key: yourkey # Set this to the node label name for your GPU-enabled worker nodes
      nodelabel_value: yourvalue # Set this to the node label value for your GPU-enabled worker nodes
 ```
 
  8. Save the configuration changes.

  9. Note: The changes will take effect after the Operator performs the next reconcile, so may take some time.  This will cause the "deeplearning" pod to be   
  restarted on the GPU-enabled worker node.

* If you prefer to use the Openshift commandline, use these steps:

  1. Login to the OpenShift cluster through the OpenShift commandline

  2. Run this command (replace the values for "yourkey" and "yourvalue" based on your node label):

oc patch icp4aclusters icp4adeploy -p '{"spec":{"ca_configuration":{"deeplearning":{"gpu_enabled": true,"nodelabel_key": "yourkey","nodelabel_value": "yourvalue"}}}}' --type=merge

  3. Note: The changes will take effect after the Operator performs the next reconcile, so may take some time.  This will cause the "deeplearning" pod to be 
  restarted on the GPU-enabled worker node.


# Access the deployed applications

- The deployment takes about 1 - 3 hours to finish depending on your selection. When you see configmap icp4adeploy-cp4ba-access-info created in the selected project, you can visit your deployment with the provided URLs.

# Uninstalling

- Access workspace by clicking “Schematics”.
- Click Workspaces.
- Find the workspace that you created for the installation.
- Click the workspace to select Actions -> Delete.
- Select checkbox for Delete workspace , Delete all associated resources 
- Type the workspace name to confirm
- Click delete.

An uninstall of Cloud Pak for Business Automation also removes the project. It takes about 30 minutes - 1 hour to finish. 

# Limitations

- Integration with IBM Automation Foundation is not supported with IBM Cloud Catalog deployments. 
- For more limitations, See https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=issues-known-limitations



# Trobuleshooting

- Install fails with db2-release-db2u-restore-morph-job pod error and DB2 deployment is not completed then you will need to uninstall existing deployment by following uninstallation steps above. Once the uninstall is finished install again will resolve the issue.


- More troubleshooing tips can be found here in product documentation. (https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=deployments-troubleshooting)
