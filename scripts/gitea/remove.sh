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
echo ">>>>$(print_timestamp) Gitea remove started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Delete project gitea"
oc delete project gitea

echo
echo ">>>>$(print_timestamp) Wait for Project gitea deletion"
wait_for_k8s_resource_disappear project/gitea

echo
echo ">>>>$(print_timestamp) Delete helm repo"
helm repo remove gitea-charts

echo
echo ">>>>$(print_timestamp) Gitea remove completed"
