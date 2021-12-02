#!/bin/bash

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) Asset Repo remove started"

echo
echo ">>>>Source internal variables"
. ../inernal-variables.sh

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Switch Project"
oc project ${PROJECT_NAME}

echo
echo ">>>>$(print_timestamp) Delete Asset Repo instance"
oc delete AssetRepository/assets

echo
echo ">>>>$(print_timestamp) Wait for AssetRepository assets deletion"
wait_for_k8s_resource_disappear AssetRepository/assets

echo
echo ">>>>$(print_timestamp) Delete Asset Repo Subscription"
oc delete subscription ibm-integration-asset-repository

echo
echo ">>>>$(print_timestamp) Wait for Asset Repo Subscription deletion"
wait_for_k8s_resource_disappear Subscription/ibm-integration-asset-repository

echo
echo ">>>>$(print_timestamp) Delete Asset Repo CSVs and wait for deletion"
CSV=`oc get csv -o name | grep asset-repository`
oc delete ${CSV}
wait_for_k8s_resource_disappear ${CSV}

CSV=`oc get csv -o name | grep couchdb`
oc delete ${CSV}
wait_for_k8s_resource_disappear ${CSV}

echo
echo ">>>>$(print_timestamp) Asset Repo remove completed"
