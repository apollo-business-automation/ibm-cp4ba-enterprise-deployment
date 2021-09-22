#!/bin/bash

# Based on https://github.com/lmenezes/cerebro

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) Cerebro install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Create Project"
oc new-project cerebro

echo
echo ">>>>$(print_timestamp) Add anyuid SCC to default SA"
oc adm policy add-scc-to-user anyuid system:serviceaccount:cerebro:default

echo
echo ">>>>$(print_timestamp) Update ConfigMap"
sed -i "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" configmap.yaml
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" configmap.yaml

echo
echo ">>>>$(print_timestamp) Create ConfigMap"
oc apply -f configmap.yaml

echo
echo ">>>>$(print_timestamp) Create Deployment"
oc apply -f deployment.yaml

echo
echo ">>>>$(print_timestamp) Wait for Deployment to be Available"
wait_for_k8s_resource_condition deployment/cerebro Available

echo
echo ">>>>$(print_timestamp) Create Service"
oc apply -f service.yaml

echo
echo ">>>>$(print_timestamp) Create Route"
oc create route edge cerebro --hostname=cerebro.${OCP_APPS_ENDPOINT} \
--service=cerebro --insecure-policy=Redirect --cert=../global-ca/wildcard.crt \
--key=../global-ca/wildcard.key --ca-cert=../global-ca/global-ca.crt

echo
echo ">>>>$(print_timestamp) Cerebro install completed"
