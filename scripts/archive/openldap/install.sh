#!/bin/bash

# Based on https://github.com/osixia/docker-openldap & https://github.com/jp-gouin/helm-openldap

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
echo ">>>>$(print_timestamp) >>>>$(print_timestamp) OpenLDAP + phpLDAPadmin install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Create Project"
oc new-project openldap

echo
echo ">>>>$(print_timestamp) Add anyuid SCC to default SA"
oc adm policy add-scc-to-user anyuid system:serviceaccount:openldap:default

echo
echo ">>>>$(print_timestamp) Add helmchart"
helm repo add helm-openldap https://jp-gouin.github.io/helm-openldap/
helm repo update

echo
echo ">>>>$(print_timestamp) Update OpenLDAP helm values"
sed -f - values.yaml > values.target.yaml << SED_SCRIPT
s|{{STORAGE_CLASS_NAME}}|${STORAGE_CLASS_NAME}|g
s|{{BASE64_UNIVERSAL_PASSWORD}}|$(echo -n ${UNIVERSAL_PASSWORD} | base64)|g
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
s|{{LDAP_HOSTNAME}}|${LDAP_HOSTNAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Install helm release"
# Custom chema LDIF based on https://stackoverflow.com/questions/45511696/creating-a-new-objectclass-and-attribute-in-openldap
helm install openldap helm-openldap/openldap-stack-ha --values values.target.yaml --version ${OPENLDAP_CHART_VERSION}

echo
echo ">>>>$(print_timestamp) Create phpLDAPadmin Route"
oc create route edge openldap-phpldapadmin --hostname=phpldapadmin.${OCP_APPS_ENDPOINT} \
--service=openldap-phpldapadmin --insecure-policy=Redirect --cert=../global-ca/wildcard.crt \
--key=../global-ca/wildcard.key --ca-cert=../global-ca/global-ca.crt

echo
echo ">>>>$(print_timestamp) Wait for phpLDAPadmin Deployment to be Available"
wait_for_k8s_resource_condition deployment/openldap-phpldapadmin Available

echo
echo ">>>>$(print_timestamp) Wait for OpenLDAP Ready state"
wait_for_k8s_resource_condition pod/openldap-openldap-stack-ha-0 Ready

echo
echo ">>>>$(print_timestamp) OpenLDAP + phpLDAPadmin install completed"
