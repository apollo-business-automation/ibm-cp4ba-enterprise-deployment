#!/bin/bash

# Based on https://hub.docker.com/_/mongo-express

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
echo ">>>>$(print_timestamp) Mongo Express install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Create Project"
oc new-project mongo-express

echo
echo ">>>>$(print_timestamp) Update Deployment"
sed -f - deployment.yaml > deployment.target.yaml << SED_SCRIPT
s|{{MONGO_EXPRESS_IMAGE_TAG}}|${MONGO_EXPRESS_IMAGE_TAG}|g
s|{{MONGODB_HOSTNAME}}|${MONGODB_HOSTNAME}|g
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Create Mongo Express Deployment"
oc apply -f deployment.target.yaml

echo
echo ">>>>$(print_timestamp) Wait for Mongo Express Deployment to be Available"
wait_for_k8s_resource_condition Deployment/mongo-express Available


echo
echo ">>>>$(print_timestamp) Create Mongo Express Service"
oc apply -f service.yaml

echo
echo ">>>>$(print_timestamp) Create Mongo Express Route"
oc create route edge mongo-express --hostname=mongo-express.${OCP_APPS_ENDPOINT} \
--service=mongo-express --insecure-policy=Redirect --cert=../global-ca/wildcard.crt \
--key=../global-ca/wildcard.key --ca-cert=../global-ca/global-ca.crt

echo
echo ">>>>$(print_timestamp) Mongo Express install completed"
