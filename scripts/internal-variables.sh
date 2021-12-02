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
