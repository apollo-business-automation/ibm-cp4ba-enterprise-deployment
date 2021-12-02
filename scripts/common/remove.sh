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
echo ">>>>$(print_timestamp) Common remove started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Switch to openshift-marketplace Project"
oc project openshift-marketplace

echo
echo ">>>>$(print_timestamp) Delete CatalogSource"
oc delete catalogsource ibm-operator-catalog

echo
echo ">>>>$(print_timestamp) Wait for CatalogSource deletion"
wait_for_k8s_resource_disappear CatalogSource/ibm-operator-catalog

echo
echo ">>>>$(print_timestamp) Common remove completed"
