#!/bin/bash

# Based on https://docker-mailserver.github.io/docker-mailserver/edge/config/advanced/kubernetes/

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
echo ">>>>$(print_timestamp) Mail install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Create Project"
oc new-project mail

echo
echo ">>>>$(print_timestamp) Add privileged and anyuid access"
# Need to chroot in mailserver
oc adm policy add-scc-to-user privileged system:serviceaccount:mail:default
oc adm policy add-scc-to-user anyuid system:serviceaccount:mail:default

echo
echo ">>>>$(print_timestamp) Create certificate key pair for postfix"
openssl genrsa -out ../global-ca/mailserver.key 2048

openssl req -new -sha256 \
-key ../global-ca/mailserver.key \
-subj "/CN=mailserver" \
-addext "subjectAltName=DNS:mailserver" \
-out ../global-ca/mailserver.csr

openssl x509 -req -extfile <(printf "subjectAltName=DNS:mailserver") -days 36500 \
-in ../global-ca/mailserver.csr -CA ../global-ca/global-ca.crt \
-CAkey ../global-ca/global-ca.key -CAcreateserial -out ../global-ca/mailserver.crt

echo
echo ">>>>$(print_timestamp) Create tls secret"
oc create secret generic tls --from-file=tls.crt=../global-ca/mailserver.crt \
--from-file=tls.key=../global-ca/mailserver.key

echo
echo ">>>>$(print_timestamp) Update PVC"
sed -f - pvc.yaml > pvc.target.yaml << SED_SCRIPT
s|{{STORAGE_CLASS_NAME}}|${STORAGE_CLASS_NAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Create pvcs"
oc apply -f pvc.target.yaml

echo
echo ">>>>$(print_timestamp) Update configmaps"
sed -f - configmaps.yaml > configmaps.target.yaml << SED_SCRIPT
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Create configmaps"
oc apply -f configmaps.target.yaml

echo
echo ">>>>$(print_timestamp) Update deployment"
sed -f - deployment.yaml > deployment.target.yaml << SED_SCRIPT
s|{{MAIL_IMAGE_TAG}}|${MAIL_IMAGE_TAG}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Create deployment"
oc apply -f deployment.target.yaml

echo
echo ">>>>$(print_timestamp) Wait for mailserver Deployment to be Available"
wait_for_k8s_resource_condition deployment/mailserver Available

echo
echo ">>>>$(print_timestamp) Create service"
oc apply -f service.yaml

echo
echo ">>>>$(print_timestamp) Mail install completed"
