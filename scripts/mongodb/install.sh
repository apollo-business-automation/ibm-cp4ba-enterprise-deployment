#!/bin/bash

# Based on https://artifacthub.io/packages/helm/bitnami/mongodb/8.3.2

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
echo ">>>>$(print_timestamp) MongoDB install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Create Project"
oc new-project mongodb

echo
echo ">>>>$(print_timestamp) Add anyuid SCC to default SA"
oc adm policy add-scc-to-user anyuid system:serviceaccount:mongodb:default

echo
echo ">>>>$(print_timestamp) Add helmchart"
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

echo
echo ">>>>$(print_timestamp) Update MongoDB helm values"
sed -f - values.yaml > values.target.yaml << SED_SCRIPT
s|{{MONGODB_IMAGE_TAG}}|${MONGODB_IMAGE_TAG}|g
s|{{STORAGE_CLASS_NAME}}|${STORAGE_CLASS_NAME}|g
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Install helm release"
helm install mongodb bitnami/mongodb --values values.target.yaml --version ${MONGODB_CHART_VERSION}

echo
echo ">>>>$(print_timestamp) Wait for MongoDB Deployment to be Available"
wait_for_k8s_resource_condition Deployment/mongodb Available

echo
echo ">>>>$(print_timestamp) MongoDB install completed"
