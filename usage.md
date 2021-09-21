# Usage & Operations

This file contains endpoints, credentials and other useful information about capabilities installed in the platform.

It is divided into sections similar to the main overview picture on the landing page [What is in the package](https://github.com/apollo-business-automation/ibm-cp4ba-enterprise-deployment/tree/main#what-is-in-the-package-).

- [Extras](#extras)
- [CP4BA - CP4BA capabilities](#cp4ba---cp4ba-capabilities)
- [CP4BA - IAF capabilities](#cp4ba---iaf-capabilities)
- [CPFS](#cpfs)
- [Pre-requisites](#pre-requisites)
- [Deployment job](#deployment-job)

## Extras

### DB2MC

As DB2 database management UI.

#### Endpoints

- DB2 Monitoring Console UI: https://db2mc.{{OCP_APPS_ENDPOINT}}/console  
- DB2 Monitoring Console REST API docs: https://db2mc.{{OCP_APPS_ENDPOINT}}/dbapi/api/index_enterprise.html  
- DB2 Monitoring Console REST API endpoint: https://db2mc.{{OCP_APPS_ENDPOINT}}/dbapi/v4

#### Credentials

- cpadmin / {{UNIVERSAL_PASSWORD}}

### Gitea

As Git server provider.

#### Endpoints

UI: https://gitea.{{OCP_APPS_ENDPOINT}}
OAS: https://gitea.{{OCP_APPS_ENDPOINT}}/api/swagger#/

####  Credentials

- Credentials you should use: cpadmin / {{UNIVERSAL_PASSWORD}}
- Initial administrative user credentials: giteaadmin / {{UNIVERSAL_PASSWORD}}

### Nexus

As package manager.

#### Endpoints

UI: https://nexus.{{OCP_APPS_ENDPOINT}}/
OAS: https://nexus.{{OCP_APPS_ENDPOINT}}/swagger-ui/

#### Credentials

- Credentials you should use: cpadmin / {{UNIVERSAL_PASSWORD}}
- Initial administrative user credentials: admin / {{UNIVERSAL_PASSWORD}}

### Roundcube

As mail client.

#### Endpoints

- UI: https://roundcube.{{OCP_APPS_ENDPOINT}}

#### Credentials

- for cpadmin: cpadmin@cp.local / {{UNIVERSAL_PASSWORD}} (you can also use only *cpadmin* without domain as username to login)
- for cpuser: cpuser@cp.local / {{UNIVERSAL_PASSWORD}} (you can also use only *cpuser* without domain as username to login)

### Cerebro

As elastic search browser.

Pre-configured for IAF elastic search.

#### Endpoints

- UI: https://cerebro.{{OCP_APPS_ENDPOINT}}

#### Credentials

- elasticsearch-admin / {{UNIVERSAL_PASSWORD}}

### AKHQ

As kafka browser.

Pre-configured for IAF Kafka with custom user (cpadmin / {{UNIVERSAL_PASSWORD}}). Admin credentials can be found in this doc in [IAF Kafka section](#ibm-automation-foundation-iaf---kafka--apicurio).

#### Endpoints

- UI: https://akhq.{{OCP_APPS_ENDPOINT}}

### Kibana

As elastic search content browser and for BAI dashboards.
#### Endpoints

- UI: https://kibana.{{OCP_APPS_ENDPOINT}}

#### Credentials

- elasticsearch-admin / {{UNIVERSAL_PASSWORD}}

### Mail

As mail server.

Any email received at *\*@cp.local* except *cpadmin@cp.local* and *cpuser@cp.local* will be delivered to *cpadmin@cp.local*.

#### Endpoints

Not exposed outside the cluster.

#### Credentials

- for cpadmin: cpadmin@cp.local / {{UNIVERSAL_PASSWORD}}
- for cpuser: cpuser@cp.local / {{UNIVERSAL_PASSWORD}}

## CP4BA - CP4BA capabilities

### Useful info

If you want to investigate the actual ansible code that is running in the operator, you can get it from running operator pod from /opt/ansible/ directory.
```bash
oc cp `oc get pod --no-headers | grep cp4a-operator | awk '{print $1}'`:/opt/ansible/ ansible

```

Order of capabilities deployment can be found in operator code in */opt/ansible/roles/icp4a/tasks/main.yml*.

To get logs from Operator.
```bash
oc logs deployment/ibm-cp4a-operator -c operator > cp4ba-operator.log

```

In operator log you can search for error using *playbook task failed*.

Operator loop in operator.log begins with output *TASK [Gathering Facts]*.

If you want to determine Operator version use the following command.
```bash
oc exec -it `oc get pod|grep ibm-cp4a-operator |awk '{print $1}'` -- cat /opt/ibm/version.txt

```

### Resource Registry (RR) (foundation pattern)

#### Endpoints

- Version of RR: https://rr-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/version  

#### Reading content of ETCD from RR container terminal

```bash
etcdctl get --from-key '' --insecure-skip-tls-verify=true --user="root:{{UNIVERSAL_PASSWORD}}" --endpoints=https://{{PROJECT_NAME}}-dba-rr-client.{{PROJECT_NAME}}.svc:2379 --insecure-transport=true --cacert="/shared/resources/tls/ca-cert.pem"

```

### User Management Services (UMS) (foundation pattern)

#### Endpoints

- UMS login: https://ums-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/ums/login  
- UMS SSO endpoint: https://ums-sso-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}  
- UMS Teams UI: https://ums-teams-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/teamserver/ui (can login with umsadmin/{{UNIVERSAL_PASSWORD}} but need to login on dedicated page at first https://ums-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/ums/login)  
- UMS Teams REST endpoint: https://ums-teams-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/teamserver/rest  
- UMS SCIM: https://ums-scim-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}  
- UMS Profiles: https://ums-profiles-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}  

####  Credentials

- cpadmin / {{UNIVERSAL_PASSWORD}}

### Business Automation Navigator (BAN) (foundation pattern)

#### Endpoints

- Admin desktop: https://navigator-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/navigator/?desktop=admin  

####  Credentials

- cpadmin / {{UNIVERSAL_PASSWORD}}

### Business Automation Studio (BAS) (foundation pattern)

#### Endpoints

- Studio UI: https://bas-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/BAStudio (Now redirects to Platform UI)
- Playback AAE Server apps list: https://pb-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/v2/applications  

####  Credentials

- cpadmin / {{UNIVERSAL_PASSWORD}}

### Business Automation Insights (BAI) (foundation pattern)

#### Endpoints

- Business Performance Center UI: https://bai-bpc-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}  
- Management endpoint: https://bai-management-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}  
- Business Performance Center UI in BAN: https://navigator-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/navigator/?desktop=BAI  
- Flink: https://bai-flink-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}  

####  Credentials

- for BAI - cpadmin / {{UNIVERSAL_PASSWORD}}
- for Flink - username: ```oc get secret $(oc get eventprocessor {{PROJECT_NAME}}-bai-event-processor -o jsonpath='{.status.endpoints[0].authentication.secret.secretName}') -o jsonpath='{.data.username}' | base64 -d``` / password: ```oc get secret $(oc get eventprocessor {{PROJECT_NAME}}-bai-event-processor -o jsonpath='{.status.endpoints[0].authentication.secret.secretName}') -o jsonpath='{.data.password}' | base64 -d```

#### Extracting generated templates from operator for debug

```bash
oc cp `oc get pod --no-headers | grep cp4a-operator | awk '{print $1}'`:/tmp/ansible-operator/runner/tmp/bai/templates/bai_all_in_one.yaml bai_all_in_one.yaml

```

### Operational Decision Manager (ODM) (decisions pattern)

You may get 400 not authorized error when accessing endpoints. In this case clear cookies and refresh browser.  

#### Endpoints

- Decision Center UI: https://odm-decisioncenter-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}  
- Decision Center OAS: https://odm-decisioncenter-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/decisioncenter-api  
- Decision Runner UI: https://odm-decisionrunner-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}  
- Decision Server Console: https://odm-decisionserverconsole-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}  
- Decision Server Runtime: https://odm-decisionserverruntime-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}  

####  Credentials

- cpadmin / {{UNIVERSAL_PASSWORD}}

### Automation Decision Services (ADS) (decisions_ads pattern)

#### Endpoints

- Administration: https://cpd-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/ads/admin-platform  
- Runtime OAS: https://ads-runtime-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/ads/runtime/api/swagger-ui  
- Runtime OAS JSON file: https://ads-runtime-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/ads/runtime/api/v1/openapi.json  
- Runtime service invocation template: https://ads-runtime-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/ads/runtime/api/v1/decision/{decisionId}/operations/{operation} (using Bearer Authentication with UMS token (https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=sign-invoking-oauth-20-protected-apis))  

####  Credentials

- cpadmin / {{UNIVERSAL_PASSWORD}}

### FileNet Content Manager (FNCM) (content pattern)

#### Endpoints

For external share you need to use ingress prefixed set of endpoints.

- ACCE console UI: https://cpe-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/acce  
- CPE WSI endpoint: https://cpe-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/wsi/FNCEWS40MTOM  
- CPE health check: https://cpe-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/P8CE/Health
- CPE ping page: https://cpe-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/FileNet/Engine
- PE ping page: https://cpe-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/peengine/IOR/ping
- PE details page: https://cpe-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/peengine/IOR/admin/help
- CSS health check: https://cpe-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/P8CE/Health/CBRDashboard
- CMIS definitions UI: https://cmis-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/openfncmis_wlp  
- CMIS endpoint: https://cmis-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/openfncmis_wlp/services (e.g. for BAW CMIS)  
- GraphiQL UI: https://graphql-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/content-services-graphql  
- GraphQL endpoint: https://graphql-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/content-services-graphql/graphql  
- External Share ingress for navigator: https://ingress-es-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/navigator/?desktop=admin
- External Share ingress for plugin: https://ingress-es-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/contentapi/plugins/sharePlugin.jar  
- External Share ingress for rest endpoint: https://ingress-es-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/contentapi/rest/share/v1/info  
- External Share ingress for desktop: https://ingress-es-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/navigator/?desktop=OS1  
- External Share ingress for external desktop: https://ingress-es-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/navigator/?desktop=ExternalShareOS1  
- Task Manager API endpoint: https://tm-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/taskManagerWeb/api/v1  

####  Credentials

- cpadmin / {{UNIVERSAL_PASSWORD}}

### Automation Application Engine (AAE) (application pattern)

#### Endpoints

- AAE Server apps list: https://ae-instance1-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/v1/applications  

####  Credentials

- cpadmin / {{UNIVERSAL_PASSWORD}}

### Automation Document Processing (ADP) (document_processing pattern)

#### Endpoints

- CDRA API: https://cdra-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/cdapi/v1/api  
- Content Project Deployment Service: https://cpds-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}} (Note: This URL is meant to use with ADP scripts and not to be accessed as is without context root)
- Viewone build info: https://viewone-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}  

####  Credentials

- cpadmin / {{UNIVERSAL_PASSWORD}}

### Business Automation Workflow Authoring (BAWAUT)

#### Endpoints

- Process Portal: https://bawaut-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/ProcessPortal  
- Process Admin: https://bawaut-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/ProcessAdmin  
- Process Inspector: https://bawaut-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/ProcessInspector  
- OAS REST API: https://bawaut-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/bpm/explorer  
- OAS REST API Operations: https://bawaut-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/bpm/explorer/?url=/ops/docs  
- Original REST API: https://bawaut-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/bpmrest-ui  
- PFS federated systems: https://pfs-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/rest/bpm/federated/v1/systems  
- Workplace: https://navigator-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/navigator/?desktop=workplace  
- Case monitor: https://navigator-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/navigator/?desktop=bawmonitor  
- Case Client: https://navigator-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/navigator/?desktop=baw  
- Case administration: https://navigator-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/navigator/?desktop=bawadmin  

####  Credentials

- cpadmin / {{UNIVERSAL_PASSWORD}}

## CP4BA - IAF capabilities

### Platform UI

#### Endpoints

- Platform UI (Zen UI): https://cpd-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/zen/

#### Credentials

- cpadmin / {{UNIVERSAL_PASSWORD}}

### Elastic Search

#### Endpoints

- Elastic Search: https://iaf-system-es-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}  

#### Credentials

- elasticsearch-admin / {{UNIVERSAL_PASSWORD}}

### Kafka & Apicurio

#### Endpoints

- Kafka: iaf-system-kafka-bootstrap-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}:443  
- Apicurio: https://iaf-system-apicurio-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}  
- Apicurio OAS: https://iaf-system-apicurio-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/api-specifications/registry/v1/openapi.json
- Apicurio API endpoint: https://iaf-system-apicurio-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/api

#### Credentials

- Username: ```oc get kafkauser icp4ba-kafka-auth -o jsonpath='{.status.username}'```  
- Password: ```oc get secret $(oc get kafkauser icp4ba-kafka-auth -o jsonpath='{.status.secret}') -o jsonpath='{.data.password}' | base64 -d```  

Apicurio has same credentials as Kafka.

Alternative custom user: cpadmin / {{UNIVERSAL_PASSWORD}}

#### Configuration for Kafka connection

- Security protocol: Sasl Ssl  
- Sasl Mechanism: SCRAM-SHA-512  
- Root CA cert (used in *Path to root CA certificates file*): ```oc get kafka iaf-system -o jsonpath='{.status.listeners[1].certificates[0]}'```  

### Process Mining

#### Endpoints

- Process Mining UI: https://cpd-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/processmining  
- Task Mining UI: https://cpd-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/taskmining  

####  Credentials

- cpadmin / {{UNIVERSAL_PASSWORD}}

#### Useful info

If you want to investigate the actual ansible code that is running in the operator, you can get it from running operator pod from /opt/ansible/ directory.
```bash
oc cp `oc get pod --no-headers | grep processmining-operator-controller-manager | awk '{print $1}'`:/opt/ansible/ pm-ansible
```

To get logs for Operator.
```bash
oc get pods -o name | grep processmining-operator-controller | xargs oc logs  > process-mining-operator.log
```

### Asset Repository

#### Endpoints

- UI: https://cpd-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/assets  

####  Credentials

- cpadmin / {{UNIVERSAL_PASSWORD}}

### RPA

#### Endpoints

- UI: https://rpa-ui-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/
- API: https://rpa-apiserver-{{PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/v1.0/en/configuration

####  Credentials

- cpadmin / {{UNIVERSAL_PASSWORD}}

## CPFS

As Cloud Pak Foundational Services.

#### Endpoints

- Console UI: https://cp-console.{{OCP_APPS_ENDPOINT}}  
- IAM login page: https://cp-console.{{OCP_APPS_ENDPOINT}}/oidc/login.jsp

#### Credentials

- for CPFS admin: cpfsadmin / {{UNIVERSAL_PASSWORD}} (IBM provided credentials (admin only))  
- for CP4BA admin: cpadmin / {{UNIVERSAL_PASSWORD}} (Enterprise LDAP)  

### License Service

#### Endpoints

- Base page: https://ibm-licensing-service-instance-ibm-common-services.{{OCP_APPS_ENDPOINT}}  
- Direct status page: https://ibm-licensing-service-instance-ibm-common-services.{{OCP_APPS_ENDPOINT}}/status?token={{token}} (*{{token}}* generated by `oc get secret ibm-licensing-token -o jsonpath={.data.token} -n ibm-common-services | base64 -d`)

#### Getting license info

Based on https://www.ibm.com/docs/en/cpfs?topic=service-obtaining-updating-api-token  
Based on https://www.ibm.com/docs/en/cpfs?topic=service-apis-retrieving-license-data#products  

```bash
TOKEN=`oc get secret ibm-licensing-token -o jsonpath={.data.token} -n ibm-common-services | base64 -d`
curl -kL https:/ibm-licensing-service-instance-ibm-common-services.{{OCP_APPS_ENDPOINT}}/snapshot?token=$TOKEN --output snapshot.zip

```

## Pre-requisites

### DB2

As DB2 database storage for the platform.

#### Endpoints

- Exposed as NodePort as found in Project *db2* in Service *c-db2ucluster-db2u-engn-svc*.

#### Credentials

- db2inst1 / {{UNIVERSAL_PASSWORD}}

### OpenLDAP + phpLDAPadmin

As LDAP directory provider and management tool.

#### Endpoints

- PHP LDAP admin management console: https://phpldapadmin.{{OCP_APPS_ENDPOINT}}/

#### Credentials

- cn=admin,dc=cp / {{UNIVERSAL_PASSWORD}}

#### Users and Groups

LDAP contains the following users in ou=Users,dc=cp. All have password {{UNIVERSAL_PASSWORD}}:  
- cpadmin  
- cpadmin1  
- cpadmin2  
- cpuser  
- cpuser1  
- cpuser2  

LDAP contains the following groups in ou=Groups,dc=cp:  
- cpadmins - members: uid=cpadmin,ou=Users,dc=cp; uid=cpadmin1,ou=Users,dc=cp; uid=cpadmin2,ou=Users,dc=cp  
- cpusers - members: uid=cpadmin,ou=Users,dc=cp; uid=cpadmin1,ou=Users,dc=cp; uid=cpadmin2,ou=Users,dc=cp; - uid=cpuser,ou=Users,dc=cp; uid=cpuser1,ou=Users,dc=cp; uid=cpuser2,ou=Users,dc=cp  
- cpusers1 - members: uid=cpuser,ou=Users,dc=cp; uid=cpuser1,ou=Users,dc=cp; uid=cpuser2,ou=Users,dc=cp  
- TaskAdmins - for FNCM TM - members: uid=cpadmin,ou=Users,dc=cp;  
- TaskAuditors - for FNCM TM - members: uid=cpadmin,ou=Users,dc=cp;
- TaskUsers - for FNCM TM - members: uid=cpadmin,ou=Users,dc=cp; uid=cpuser,ou=Users,dc=cp  

### MSSQL

As DB server for RPA.

#### Endpoints

- Not exposed outside the cluster.

#### Credentials

- sa / {{UNIVERSAL_PASSWORD}}

## Deployment job

### Global CA

If you haven't provided your own key and crt pair in configuration, new one was generated in Project *automagic* in Secret *global-ca*.

You can import *global-ca.crt* to you operating system or browser to automatically trust all the certificates used in the platform.
