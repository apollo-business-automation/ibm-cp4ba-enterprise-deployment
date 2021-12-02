#!/bin/bash

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) PM remove started"

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
echo ">>>>$(print_timestamp) Delete PM instance"
oc delete ProcessMining/processmining

echo
echo ">>>>$(print_timestamp) Wait for ProcessMining processmining deletion"
wait_for_k8s_resource_disappear ProcessMining/processmining

echo
echo ">>>>$(print_timestamp) Delete PM Secret"
oc delete secret pm-tls-secret

echo
echo ">>>>$(print_timestamp) Delete PM Subscription"
oc delete subscription processmining-subscription

echo
echo ">>>>$(print_timestamp) Wait for PM Subscription deletion"
wait_for_k8s_resource_disappear Subscription/processmining-subscription

echo
echo ">>>>$(print_timestamp) Delete PM CSV"
CSV=`oc get csv -o name | grep processmining`
oc delete ${CSV}

echo
echo ">>>>$(print_timestamp) Wait for PM CSV deletion"
wait_for_k8s_resource_disappear ${CSV}

echo
echo ">>>>$(print_timestamp) PM remove completed"
