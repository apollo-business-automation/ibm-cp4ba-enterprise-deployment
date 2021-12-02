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
echo ">>>>$(print_timestamp) CP4BA repository install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Download and extract installation repository"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=operator-preparing-log-file-storage
curl https://github.com/IBM/cloud-pak/raw/master/repo/case/ibm-cp-automation-${CP4BA_CASE_VERSION}.tgz -L -o ibm-cp-automation-${CP4BA_CASE_VERSION}.tgz
exit_test $? "Download CP4BA CASE repository Failed"
tar xzvf ibm-cp-automation-${CP4BA_CASE_VERSION}.tgz
tar -xvzf ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-k8s-${CP4BA_CASE_CERT_K8S_VERSION}.tar

echo
echo ">>>>$(print_timestamp) CP4BA repository install completed"
