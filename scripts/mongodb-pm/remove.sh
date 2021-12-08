#!/bin/bash

echo
echo ">>>>Source internal variables"
. ../internal-variables.sh

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) MongoDB PM remove started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Delete project mongodb-pm"
oc delete project mongodb-pm

echo
echo ">>>>$(print_timestamp) Wait for Project mongodb-pm deletion"
wait_for_k8s_resource_disappear project/mongodb-pm

echo
echo ">>>>$(print_timestamp) Delete helm repo"
helm repo remove bitnami

echo
echo ">>>>$(print_timestamp) MongoDB PM remove completed"
