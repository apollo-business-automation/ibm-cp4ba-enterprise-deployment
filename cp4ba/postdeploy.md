# CP4BA post-deploy

Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=deployments-completing-post-deployment-tasks

The following list specifies when you need to perform particular post-deployment steps
- [Business Automation Navigator (BAN) (foundation pattern)](#business-automation-navigator-ban-foundation-pattern)
  - [Enable Daeja for Office](#enable-daeja-for-office) - When you want to open MS Office documents in Navigator Daeja Viewer
  - [Add Daeja license](#add-daeja-license) - When you want to open MS Office documents in Navigator Daeja Viewer and use Permanent Redaction of content.
- [Business Automation Studio (BAS) (foundation pattern)](#business-automation-studio-bas-foundation-pattern)
  - [Deploy toolkits and configurators](#deploy-toolkits-and-configurators) - When you want to call ODM from Business Application using Automation Services.
  - [Apps deployment](#apps-deployment) - When you want to deploy or see which Business Applications were deployed in Playback Application Engine.
- [Business Automation Insights (BAI) (foundation pattern)](#business-automation-insights-bai-foundation-pattern)
  - [Configure Workforce insights](#configure-workforce-insights) - When you want to use Workforce Insights.
- [Operational Decision Manager (ODM) (decisions pattern)](#operational-decision-manager-odm-decisions-pattern)
  - [BAI event emitter](#bai-event-emitter) - When you want to enable BAI event emitting for your Rule Application.
  - [Rule designer in eclipse](#rule-designer-in-eclipse) - When you want to install Rule Designer in Eclipse to develop Rule Applications.
  - [Rule designer UMS OpenID Connect](#rule-designer-ums-openid-connect) - When you want to deploy Rule Applications from your local Rule Designer to ODM.
- [Automation Decision Services (ADS) (decisions_ads pattern)](#automation-decision-services-ads-decisions_ads-pattern)
  - [ADS project git repo & connection](#ads-project-git-repo--connection) - When you want to connect your ADS solution to GIT repository.
  - [Connect Nexus for external libraries](#connect-nexus-for-external-libraries) - When you want to use published external libraries from Nexus.
  - [Develop custom libraries](#develop-custom-libraries) - When you want to create your custom ADS libraries.
- [FileNet Content Manager (FNCM) (content pattern)](#filenet-content-manager-fncm-content-pattern)
  - [Update Google OIDC redirect URIs](#update-google-oidc-redirect-uris) - (don't use now) When you configured Google ID for External Share.
  - [BAN desktop for OS1](#ban-desktop-for-os1) - To update VIewer Map for OS1 Desktop when custom Viewer Map has been created in TODO link for MS Office documents.
  - [External Share](#external-share) - (don't use now) When you want to use External Share.
  - [External Share capability in BAN](#external-share-capability-in-ban) - (don't use now) When you want to use External Share.
  - [Task manager settings](#task-manager-settings) - When you want to use Task Manager.
- [Automation Document Processing (ADP) (document_processing pattern)](#automation-document-processing-adp-document_processing-pattern)
  - [Connect ADP project to Git](#connect-adp-project-to-git) - When you need to finish ADP configuration. Without Git connection, you cannot publish your solution.


For some of the tasks you need to interact with OpenShift using oc CLI. Use the following templates to log in and switch project.
```bash
# Either Username + Password
oc login --server={{OCP_API_ENDPOINT}} -u {{OCP_CLUSTER_ADMIN}} -p {{OCP_CLUSTER_ADMIN_PASSWORD}}
# Or Token
oc login --server={{OCP_API_ENDPOINT}} --token={{OCP_CLUSTER_TOKEN}}


oc project {{PROJECT_NAME}}

```


For logging in to CP4BA pillars use *Authentication type: Enterprise LDAP* and user *cpadmin* with password "{{UNIVERSAL_PASSWORD}}" if not stated otherwise.

## Business Automation Navigator (BAN) (foundation pattern)

Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=tasks-completing-post-deployment-business-automation-navigator

### Enable Daeja for Office

Go to navigator https://navigator-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/navigator/?desktop=admin  
Switch to Viewer Maps tab  
Click on Default viewer map  
Click Copy  

Name: Virtual Viewer  
Click on row FileNet Content Manager | Daeja ViewONE Virtual
Click Edit  
Check *All file types* checkbox  
Dismiss the warning  
Click OK  
Click Save and Close  

This viewer can be later used for CPE desktop.  

### Add Daeja license

Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=tasks-completing-post-deployment-business-automation-navigator point 2.  
License files generated following https://www.ibm.com/docs/en/daeja-viewone/5.0.7?topic=modules-enabling-viewer-add-in-content-navigator

License files have already been copied

Go to navigator https://navigator-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/navigator/?desktop=admin  
Switch to Settings section  
Switch to Daeja ViewONE tab  
Switch to Server section  
For License file path set Use the custom license files path with value of */opt/ibm/wlp/usr/servers/defaultServer/configDropins/overrides*  
Click Save and Close  

Restart navigator by deleting navigator-deploy pod.
```bash
oc delete `oc get pod -o name | grep navigator | cut -d "/" -f 2`

```

## Business Automation Studio (BAS) (foundation pattern)

Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=tasks-completing-post-deployment-business-automation-studio

### Deploy toolkits and configurators

Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=designer-downloadable-toolkits

To your local system download the following
- TWX file from https://github.com/icp4a/odm-toolkit/tree/master/contribution/1.2/Action%20Configurator
- TWX file from https://github.com/icp4a/odm-toolkit/tree/master/contribution/1.2/Toolkit

Go to Studio https://bas-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/BAStudio/build/index.jsp?#/apps/platformRepo  
Login with Enterprise LDAP with cpadmin / {{UNIVERSAL_PASSWORD}}  

Click Toolkits  
Click Import  
Import all files that you downloaded one by one  
Some of them are used as Configurators, don't be confused that they don't appear in the list of toolkits.  

### Apps deployment

Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=applications-publishing

Go to Navigator https://navigator-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/navigator/?desktop=admin

Go to Connections  
Click New Connection > App Service  
Display name: PB  
App Service endpoint URL: https://{{PROJECT_NAME}}-pbk-ae-service/v1/applications  
Click Connect  
Click Save and Close  

You can import apps from Studio and create desktops for them (see referenced guide in this section)  
You can also use full featured standalone AAE if deployed. Connection was created automatically.


## Business Automation Insights (BAI) (foundation pattern)

### Configure Workforce insights

Part of WFI configuration has already been done automatically.

Set up WFI following https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=dashboards-enabling-workforce-insights

## Operational Decision Manager (ODM) (decisions pattern)

Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=tasks-completing-post-deployment-operational-decision-manager

### BAI event emitter

After you have some rule project ready, configure it to emit BAI events using https://www.ibm.com/docs/en/odm/8.10?topic=properties-built-in-ruleset-odm-event-emitter

### Rule designer in eclipse

Based on https://www.ibm.com/docs/odm/8.10?topic=810x-installing-rule-designer  

Download Eclipse 4.7 from https://archive.eclipse.org/eclipse/downloads/drops4/R-4.7-201706120950/ (Platform Runtime Binary section)  
Open it, Help > Install New Software > Select *Work with: All Available Sites* > In *type filter text* Search for *Eclipse Marketplace*  
Select *Marketplace Client* and install it (Next, Next, Accept, Finish).  
Restart eclipse.  
In the following URL you may want to use different rule designer version, replace 8105 with the appropriate version you need.  
Go to https://marketplace.eclipse.org/content/ibm-operational-decision-manager-developers-v-8105-rule-designer  
Drag and drop Install button in your eclipse.  
Confirm > Accept license > Finish  
Confirm pop-up with Install anyway  
Wait for the installation completion.  
Restart eclipse  
Window > Perspective > Open Perspective > Other > Rule  

### Rule designer UMS OpenID Connect
Based on https://www.ibm.com/docs/en/odm/8.10?topic=parties-configuring-rule-designer

Copy and edit data/odm/oidc-providers.json to you eclipse directory  
Parameters can be seen in pod
```bash
POD=`oc get pod -o name | grep decisionserverconsole`
oc exec $POD -- cat /liberty/wlp/usr/servers/defaultServer/authOidc/openIdParameters.properties

```

Based on https://www.ibm.com/docs/en/odm/8.10?topic=designer-passing-parameters-rule  
Copy data/odm/truststore.jks to you eclipse directory  
Add the following to eclipse.ini  
```text
-Dcom.ibm.rules.authentication.oidcconfig=oidc-providers.json
-Djavax.net.ssl.trustStore=truststore.jks
-Djavax.net.ssl.trustStorePassword={{UNIVERSAL_PASSWORD}}
```

When configuring RES connection in Deployment use  
URL: https://odm-decisionserverconsole-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/res  
Method: OpenID Connect  
Provider: ums  

When configuring Decision Center use  
URL: https://odm-decisioncenter-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/teamserver  
Authentication: OpenID Connect  
Provider: ums


## Automation Decision Services (ADS) (decisions_ads pattern)

Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=tasks-completing-post-deployment-automation-decision-services

### ADS project git repo & connection

Needs to be done for every project individually.  
Create Repository. Change *name* in the payload to correspond to your project name.
```bash
curl --insecure --request POST "https://gitea.{{OCP_APPS_ENDPOINT}}/api/v1/orgs/ads/repos" \
--header  "Content-Type: application/json" \
--user 'cpadmin:{{UNIVERSAL_PASSWORD}}' \
--data-raw '
{
  "auto_init": false,
  "default_branch": "master",
  "description": "",
  "gitignores": "",
  "issue_labels": "",
  "license": "",
  "name": "sandbox",
  "private": true,
  "readme": "",
  "template": false,
  "trust_model": "default"
}
'

```

Open your ADS Sandbox project  
On the top right, click Connect  

Repository URI: https://gitea.{{OCP_APPS_ENDPOINT}}/ads/sandbox.git  (adjust *sandbox*)  
Username: cpadmin  
Password: {{UNIVERSAL_PASSWORD}}  
Click Connect

### Connect Nexus for external libraries

Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=services-configuring-credentials-maven-repository-manager  

Open https://cpd-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/ads/admin-platform  
Click New  
ID: https://nexus.{{OCP_APPS_ENDPOINT}}/repository/maven-releases/  
Authentication type: USERNAME  
Username: cpadmin  
Password: {{UNIVERSAL_PASSWORD}}  
Credentials type: MAVEN  

### Develop custom libraries

To find out how to create and add External libraries to ADS, follow https://github.com/icp4a/automation-decision-services-samples/tree/21.0.1/samples/ExternalLibraryStart

To be able to follow the above guide from my environment, I needed to perform the following.

Add settings for Nexus in my local maven settings .m2\settings.xml (Available in Project *automagic*, in ConfigMap *nexus-maven-settings* in *settings.xml* file)  


Installed JDK 16 Oracle, added to path.

Add Global CA to jdk/jre cacerts.  
Run mvn command with -Djavax.net.debug=ssl to determine the location of used cacerts file.  
In my case: C:\Program Files\Java\jdk-16.0.1\lib\security\cacerts  
Open KeyStore Explorer as Administrator, open this cacerts, no password.  
Import Global CA crt (available in *automagic* Project in global-ca Secret if not provided), save without password.  

Installed VSCode and added Java Extension Pack


## FileNet Content Manager (FNCM) (content pattern)

Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=tasks-completing-post-deployment-filenet-content-manager

### Update Google OIDC redirect URIs

If you plan to use Google ID for External Share  
Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=manager-configuring-redirect-url-identity-provider and  
on https://developers.google.com/identity/protocols/oauth2/openid-connect#setredirecturi  
Watch video and follow with your own google account and Client ID you used in the pre-deploy section  
[Video fncm-es-google-oidc-post.mp4 download](../assets/fncm-es-google-oidc-post.mp4?raw=true) 
#TODO errata for redirect uris when this start to work

### BAN desktop for OS1

If desktop OS1 already exists, modify its viewer map

Go to Navigator  
https://navigator-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/navigator/?desktop=admin  

Go to *Desktops*  
Click *New Desktop*  
Choose *Platform and Content*  

New Desktop screen  
Name: OS1  
ID: OS1  
Connection: OS1  
Viewer map: Virtual Viewer  

Click *Save and Close*  

### External Share

Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=manager-configuring-external-share-after-deployment

If you plan to use External Share  

Configure SMTP  
Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=users-configuring-content-platform-engine-external-sharing point 3

Go to Acce console https://cpe-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/acce/  
Login with Enterprise LDAP with cpadmin / {{UNIVERSAL_PASSWORD}}  
On P8DOMAIN domain navigate to *SMTP Subsystem*  
Check *Enable email services*  
SMTP host: {{MAIL_HOSTNAME}}  
SMTP port: 25  
Email from ID: system@cp.local 
Default email reply-to ID: system@cp.local 
Email login ID: mailuser  
Email login password: {{UNIVERSAL_PASSWORD}}  
Click Save  


Configure external LDAP in FNCM CPE  
If you plan to use external LDAP for External Share  
Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=users-configuring-content-platform-engine-external-sharing point 2

Go to Acce console https://cpe-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/acce/  
On P8DOMAIN domain navigate to *Directory Configuration*  
Click on ExternalRealm  
find *Exclude From Authenticated Users* property and set it to True  
click Save  
click Close  


Document class access  
If you plan to use external LDAP for External Share  
Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=users-configuring-content-platform-engine-external-sharing point 4  

Go to Acce console https://cpe-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/acce/  
Navigate to OS1 object store > Data Design > Classes > Document > Security tab  
Click Add Permissions > Add User/Group Permission  
Search in realm: ExternalRealm (o=cpext)    
Search by: #  
Click Search  
Add *#REALM-USERS* to *Selected Users and Groups*  
Permission group: View all properties, Create instance  
Click OK  
Click Save  

Folder class access  
If you plan to use external LDAP for External Share  
Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=users-configuring-content-platform-engine-external-sharing point 5

Go to Acce console https://cpe-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/acce/  
Navigate to OS1 object store > Data Design > Classes > Folder > Security tab  
Click Add Permissions > Add User/Group Permission  
Search in realm: ExternalRealm (o=cpext)  
Search by: #  
Click Search  
add *#REALM-USERS* to *Selected Users and Groups*  
Permission group: View all properties, Create instance  
Click OK  
Click Save  

### External Share capability in BAN

Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=cesad-configuring-share-plug-in-in-business-automation-navigator  
Based on https://www.ibm.com/docs/en/content-navigator/3.0.x?topic=components-configuring-external-share  

If you plan to use External Share  

To successfully configure External share you will need to use Ingress access to BAN.
Go to navigator https://ingress-es-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/navigator/?desktop=admin  
If a pop-up occurs, click Cancel  
Go to Plug-ins  
Click New Plug-in  

New Plug-in screen  
JAR file path: https://ingress-es-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/contentapi/plugins/sharePlugin.jar  
Click Load  
Click Save  
REST API URL: https://ingress-es-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/contentapi/rest/share/v1  
Click Verify  
Repositories: select OS1  
Click Configure Share  
 
Configure Share for OS1 screen  
External URL: https://ingress-es-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/navigator  
External desktop: New desktop  
  Desktop name: External Share OS1  
  Desktop ID: ExternalShareOS1  
Consent agreement: Welcome to CP4A  
Click OK  
This may take some time, and the request can time out. Click OK after a minute again and it should complete successfully. In the mean time External share container is configuring object store behind the scenes.  
Click Save and Close  

Based on https://www.ibm.com/docs/en/content-navigator/3.0.x?topic=share-configuring-menu-action  

Navigate to Menus  
Filter for *Default document context menu*  
Select the first occurrence  
Click Copy  

New Menu screen  
Name: Share Document Context Menu  
Move Share from *Available* to *Selected:*  
Move it up under *Preview*  
Click Save and Close  

Filter for *Default folder context menu*  
Select the first occurrence  
Click Copy  

New Menu screen  
Name: Share Folder Context Menu  
Move Share from *Available* to *Selected:*  
Move it up under *Delete*  
Click Save and Close  

Navigate to Desktops  
Click on OS1  
Click Edit  
Click Menus tab  
Under Context Menus > Content Context Menus  
Document context menu: Share Document Context Menu  
Folder context menu: Share Folder Context Menu  
Click save and Close  

If you want to share content, use https://ingress-es-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/navigator/?desktop=OS1

### Task manager settings

Go to navigator https://ban-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/navigator/?desktop=admin  
Go to Settings  
Go to General  
Go to Task Manager section  
Switch Enable  
Task manager service URL: https://tm-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/taskManagerWeb/api/v1  
Task manager log directory: /opt/ibm/viewerconfig/logs/  
Task manager administrator user ID: cpadmin  
Task manager administrator password: {{UNIVERSAL_PASSWORD}}  
Click Save and Close  
Refresh browser  

## Automation Document Processing (ADP) (document_processing pattern)

Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=tasks-completing-post-deployment-document-processing?view=kc

### Connect ADP project to Git

Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=processing-setting-up-remote-git-organization

Needed if you want to be able to deploy Share, Version and Deploy ADP project

Go to ADP project  
Click Configure  
Switch to Git server configuration  
Git server organization URL: https://gitea.{{OCP_APPS_ENDPOINT}}/adp
Username: cpadmin  
Type of credentials: Password  
Credentials: {{UNIVERSAL_PASSWORD}}  
Click Test  
Click Save  
