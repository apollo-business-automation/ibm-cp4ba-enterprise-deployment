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
echo ">>>>$(print_timestamp) Common install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Add CatalogSource"
oc apply -f catalogsource.yaml

echo
echo ">>>>$(print_timestamp) Wait catalogsource READY state"
oc project openshift-marketplace
wait_for_k8s_resource_condition_generic catalogsource/ibm-operator-catalog ".status.connectionState.lastObservedState" READY

echo
echo ">>>>$(print_timestamp) Common install completed"
