#!/bin/bash

# Based on https://github.com/tchiotludo/akhq

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) AKHQ install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Create Project"
oc new-project akhq

echo
echo ">>>>$(print_timestamp) Add helmchart"
helm repo add akhq https://akhq.io/
helm repo update

echo
echo ">>>>$(print_timestamp) Generate truststore"
rm -f truststore.jks
keytool -import -destkeystore truststore.jks -deststoretype jks -deststorepass ${UNIVERSAL_PASSWORD} -alias global-ca -file ../global-ca/global-ca.crt -noprompt
trustore_base64=`base64 -w 0 truststore.jks`

echo
echo ">>>>$(print_timestamp) Update gitea helm values"
yq w -i values.yaml kafkaSecrets.truststorejks "${trustore_base64}"
sed -i "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" values.yaml
sed -i "s|{{OCP_APPS_ENDPOINT}}|${OCP_APPS_ENDPOINT}|g" values.yaml
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" values.yaml

echo
echo ">>>>$(print_timestamp) Install helm release"
helm install akhq akhq/akhq --values values.yaml --version 0.2.3

echo
echo ">>>>$(print_timestamp) Create akhq Route"
oc create route edge akhq --hostname=akhq.${OCP_APPS_ENDPOINT} \
--service=akhq --insecure-policy=Redirect --cert=../global-ca/wildcard.crt \
--key=../global-ca/wildcard.key --ca-cert=../global-ca/global-ca.crt

echo
echo ">>>>$(print_timestamp) Wait for akhq Deployment to be Available"
wait_for_k8s_resource_condition Deployment/akhq Available

echo
echo ">>>>$(print_timestamp) AKHQ install completed"
