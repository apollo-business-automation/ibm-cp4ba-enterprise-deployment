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
sed -i "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" deployment.yaml
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" deployment.yaml
sed -i "s|{{BASE64_ELASTIC_CREDENTIALS}}|"$(echo -n elasticsearch-admin:${UNIVERSAL_PASSWORD} | base64)"|g" deployment.yaml

echo
echo ">>>>$(print_timestamp) Create Deployment"
oc apply -f deployment.yaml

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
