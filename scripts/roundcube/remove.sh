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
echo ">>>>$(print_timestamp) Roundcube remove started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Delete project roundcube"
oc delete project roundcube

echo
echo ">>>>$(print_timestamp) Wait for Project roundcube deletion"
wait_for_k8s_resource_disappear project/roundcube

echo
echo ">>>>$(print_timestamp) Roundcube remove completed"
