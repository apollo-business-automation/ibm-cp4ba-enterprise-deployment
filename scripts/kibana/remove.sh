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
echo ">>>>$(print_timestamp) Kibana remove started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Delete project kibana"
oc delete project kibana

echo
echo ">>>>$(print_timestamp) Wait for Project kibana deletion"
wait_for_k8s_resource_disappear project/kibana

echo
echo ">>>>$(print_timestamp) Kibana remove completed"
