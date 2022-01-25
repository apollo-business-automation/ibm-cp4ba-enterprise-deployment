#!/bin/bash

echo
echo ">>>>Source internal variables"
. ../internal-variables.sh

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) Nexus install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Create Project"
oc new-project nexus

echo
echo ">>>>$(print_timestamp) Add OperatorGroup"
oc apply -f operatorgroup.yaml

echo
echo ">>>>$(print_timestamp) Update Subscription"
sed -f - subscription.yaml > subscription.target.yaml << SED_SCRIPT
s|{{NEXUS_CHANNEL}}|${NEXUS_CHANNEL}|g
s|{{NEXUS_STARTING_CSV}}|${NEXUS_STARTING_CSV}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add Subscription"
oc apply -f subscription.target.yaml

manage_manual_operator nxrm-operator-certified nxrm-operator-certified

echo
echo ">>>>$(print_timestamp) Wait for NexusRepo CRD to be Established"
wait_for_k8s_resource_condition CustomResourceDefinition/nexusrepos.sonatype.com Established

echo
echo ">>>>$(print_timestamp) Update NexusRepo instance"
sed -f - nexusrepo.yaml > nexusrepo.target.yaml << SED_SCRIPT
s|{{STORAGE_CLASS_NAME}}|${STORAGE_CLASS_NAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Add NexusRepo instance"
oc apply -f nexusrepo.target.yaml

echo
echo ">>>>$(print_timestamp) Wait for nexus Deployment to be Available"
wait_for_k8s_resource_condition deployment/nexusrepo-sonatype-nexus Available ${DEFAULT_ATTEMPTS_2} ${DEFAULT_DELAY_2}

echo
echo ">>>>$(print_timestamp) Create nexus Route"
oc create route edge nexus --hostname=nexus.${OCP_APPS_ENDPOINT} \
--service=nexusrepo-sonatype-nexus-service --insecure-policy=Redirect --cert=../global-ca/wildcard.crt \
--key=../global-ca/wildcard.key --ca-cert=../global-ca/global-ca.crt

echo
echo ">>>>$(print_timestamp) Wait for Route to be Admitted"
wait_for_k8s_resource_condition_generic route/nexus ".status.ingress[0].conditions[0].status" True

echo
echo ">>>>$(print_timestamp) Change default admin password"
curl --insecure --request PUT "https://nexus.${OCP_APPS_ENDPOINT}/service/rest/v1/security/users/admin/change-password" \
--header 'Content-Type: text/plain' \
--user 'admin:admin123' \
--data-raw "${UNIVERSAL_PASSWORD}"

echo
echo ">>>>$(print_timestamp) Create LDAP connection"
curl --insecure --request POST "https://nexus.${OCP_APPS_ENDPOINT}/service/rest/v1/security/ldap" \
--header 'Content-Type: application/json' \
--user "admin:${UNIVERSAL_PASSWORD}" \
--data-raw '
{
  "name": "LDAP",
  "protocol": "ldap",
  "host": "'${LDAP_HOSTNAME}'",
  "port": 389,
  "searchBase": "dc=cp",
  "authScheme": "SIMPLE",
  "authRealm": "cp.local",
  "authUsername": "cn=admin,dc=cp",
  "connectionTimeoutSeconds": 30,
  "connectionRetryDelaySeconds": 300,
  "maxIncidentsCount": 3,
  "userBaseDn": "ou=Users",
  "userSubtree": false,
  "userObjectClass": "inetOrgPerson",
  "userLdapFilter": "",
  "userIdAttribute": "uid",
  "userRealNameAttribute": "cn",
  "userEmailAddressAttribute": "mail",
  "userPasswordAttribute": "",
  "ldapGroupsAsRoles": true,
  "groupType": "static",
  "groupBaseDn": "ou=Groups",
  "groupSubtree": false,
  "groupObjectClass": "groupOfNames",
  "groupIdAttribute": "cn",
  "groupMemberAttribute": "member",
  "groupMemberFormat": "uid=${username},ou=Users,dc=CP",
  "authPassword": "'${UNIVERSAL_PASSWORD}'"
}'

echo
echo ">>>>$(print_timestamp) Add new role for cpadmins with group cpadmins as Nexus admins"
curl --insecure --request POST "https://nexus.${OCP_APPS_ENDPOINT}/service/rest/v1/security/roles" \
--header 'Content-Type: application/json' \
--user "admin:${UNIVERSAL_PASSWORD}" \
--data-raw '
{
  "id": "cpadmins",
  "name": "cpadmins",
  "description": "cpadmins",
  "privileges": [
    "nx-all"
  ],
  "roles": [
    "nx-admin"
  ]
}'

echo
echo ">>>>$(print_timestamp) Disable Anonymous access"
curl --insecure --request PUT "https://nexus.${OCP_APPS_ENDPOINT}/service/rest/v1/security/anonymous" \
--header 'Content-Type: application/json' \
--user "admin:${UNIVERSAL_PASSWORD}" \
--data-raw '
{
  "enabled": false,
  "userId": "anonymous",
  "realmName": "NexusAuthorizingRealm"
}'

echo
echo ">>>>$(print_timestamp) Replace maven settings file with real values"
sed -f - maven-settings.xml > maven-settings.target.xml << SED_SCRIPT
s|{{OCP_APPS_ENDPOINT}}|${OCP_APPS_ENDPOINT}|g
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Apply maven settings.xml"
mkdir -p ~/.m2
mv -f ~/.m2/settings.xml ~/.m2/settings.xml.bak
cp maven-settings.target.xml ~/.m2/settings.xml

if [[ $CONTAINER_RUN_MODE == "true" ]]; then
  oc project automagic
  oc create cm nexus-maven-settings --from-file=settings.xml=maven-settings.target.xml -o yaml --dry-run=client | oc apply -f -
fi

echo
echo ">>>>$(print_timestamp) Nexus install completed"
