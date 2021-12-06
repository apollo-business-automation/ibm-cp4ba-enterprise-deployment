#!/bin/bash

# Based on https://github.com/tchiotludo/akhq

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
echo ">>>>$(print_timestamp) AKHQ install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Create Project"
oc new-project akhq

echo
echo ">>>>$(print_timestamp) Add anyuid SCC to default SA"
oc adm policy add-scc-to-user anyuid system:serviceaccount:akhq:default

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
echo ">>>>$(print_timestamp) Update akhq helm values"
sed -f - values.yaml > values.target.yaml << SED_SCRIPT
s|{{TRUST_STORE}}|${trustore_base64}|g
s|{{CP4BA_PROJECT_NAME}}|${CP4BA_PROJECT_NAME}|g
s|{{OCP_APPS_ENDPOINT}}|${OCP_APPS_ENDPOINT}|g
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Install helm release"
helm install akhq akhq/akhq --values values.target.yaml --version ${AKHQ_CHART_VERSION}

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
