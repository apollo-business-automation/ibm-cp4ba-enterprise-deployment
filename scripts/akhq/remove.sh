#!/bin/bash

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) AKHQ remove started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Delete project gitea"
oc delete project akhq

echo
echo ">>>>$(print_timestamp) Wait for Project gitea deletion"
wait_for_k8s_resource_disappear project/akhq

echo
echo ">>>>$(print_timestamp) Delete helm repo"
helm repo remove akhq

echo
echo ">>>>$(print_timestamp) AKHQ remove completed"
