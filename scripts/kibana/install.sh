#!/bin/bash

echo
echo ">>>>Source internal variables"
. ../inernal-variables.sh

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) Kibana install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Create Project"
oc new-project kibana

echo
echo ">>>>$(print_timestamp) Update Deployment"
sed -f - deployment.yaml > deployment.target.yaml << SED_SCRIPT
s|{{CP4BA_PROJECT_NAME}}|${CP4BA_PROJECT_NAME}|g
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
s|{{KIBANA_IMAGE_TAG}}|${KIBANA_IMAGE_TAG}|g
s|{{BASE64_ELASTIC_CREDENTIALS}}|$(echo -n elasticsearch-admin:${UNIVERSAL_PASSWORD} | base64)|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Create Deployment"
oc apply -f deployment.target.yaml

echo
echo ">>>>$(print_timestamp) Create Service"
oc apply -f service.yaml

echo
echo ">>>>$(print_timestamp) Create Route"
oc create route edge kibana --hostname=kibana.${OCP_APPS_ENDPOINT} \
--service=kibana --insecure-policy=Redirect --cert=../global-ca/wildcard.crt \
--key=../global-ca/wildcard.key --ca-cert=../global-ca/global-ca.crt

echo
echo ">>>>$(print_timestamp) Kibana install completed"
