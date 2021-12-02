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
echo ">>>>$(print_timestamp) PM install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Switch Project"
oc project ${PROJECT_NAME}

echo
echo ">>>>$(print_timestamp) Security"
# Based on https://www.ibm.com/docs/en/cloud-paks/1.0?topic=platform-ssl-certificates
oc create secret generic pm-tls-secret \
--from-file=tls.crt=../global-ca/wildcard.crt \
--from-file=tls.key=../global-ca/wildcard.key \
--from-file=ca.crt=../global-ca/global-ca.crt

echo
echo ">>>>$(print_timestamp) Install Operator"
oc apply -f subscription.yaml

echo
echo ">>>>$(print_timestamp) Wait for Operator Deployment to be Available"
wait_for_k8s_resource_condition deployment/processmining-operator-controller-manager Available

echo
echo ">>>>$(print_timestamp) Wait for ProcessMining CRD to be Established"
wait_for_k8s_resource_condition CustomResourceDefinition/processminings.processmining.ibm.com Established

echo
echo ">>>>$(print_timestamp) Add ProcessMining instance"
oc apply -f processmining.yaml

echo
echo ">>>>$(print_timestamp) Wait for ProcessMining instance Ready state"
# Validate successful deployment by following https://www.ibm.com/docs/en/cloud-paks/1.0?topic=platform-how-validate-successful-installation
wait_for_k8s_resource_condition ProcessMining/processmining Ready ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) PM install completed"
