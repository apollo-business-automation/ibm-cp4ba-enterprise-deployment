#!/bin/bash

# Based on https://github.com/roundcube/roundcubemail-docker/blob/master/examples/kubernetes.yaml

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
echo ">>>>$(print_timestamp) Roundcube install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Create Project"
oc new-project roundcube

echo
echo ">>>>$(print_timestamp) Add anyuid access"
oc adm policy add-scc-to-user anyuid system:serviceaccount:roundcube:default

echo
echo ">>>>$(print_timestamp) Update PVC"
sed -i "s|{{STORAGE_CLASS_NAME}}|${STORAGE_CLASS_NAME}|g" pvcs.yaml

echo
echo ">>>>$(print_timestamp) Create pvcs"
oc apply -f pvcs.yaml

echo
echo ">>>>$(print_timestamp) Create configmaps"
oc apply -f configmaps.yaml

echo
echo ">>>>$(print_timestamp) Create secrets"
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" secrets.yaml
oc apply -f secrets.yaml

echo
echo ">>>>$(print_timestamp) Create services"
oc apply -f services.yaml

echo
echo ">>>>$(print_timestamp) Create roundcube DB deployment"
oc apply -f db-deployment.yaml

echo
echo ">>>>$(print_timestamp) Wait for roundcubedb Deployment to be Available"
wait_for_k8s_resource_condition deployment/roundcubedb Available

echo
echo ">>>>$(print_timestamp) Create roundcube deployment"
oc apply -f deployment.yaml

echo
echo ">>>>$(print_timestamp) Wait for roundcubemail Deployment to be Available"
wait_for_k8s_resource_condition deployment/roundcubemail Available

echo
echo ">>>>$(print_timestamp) Create roundcube nginx deployment"
oc apply -f nginx-deployment.yaml

echo
echo ">>>>$(print_timestamp) Wait for roundcubenginx Deployment to be Available"
wait_for_k8s_resource_condition deployment/roundcubenginx Available

echo
echo ">>>>$(print_timestamp) Create roundcube Route"
oc create route edge roundcube --hostname=roundcube.${OCP_APPS_ENDPOINT} \
--service=roundcubenginx --insecure-policy=Redirect --cert=../global-ca/wildcard.crt \
--key=../global-ca/wildcard.key --ca-cert=../global-ca/global-ca.crt

echo
echo ">>>>$(print_timestamp) Roundcube install completed"
