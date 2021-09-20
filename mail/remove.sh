#!/bin/bash

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) Mail remove started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Delete project mail"
oc delete project mail

echo
echo ">>>>$(print_timestamp) Wait for Project mail deletion"
wait_for_k8s_resource_disappear project/mail

echo
echo ">>>>$(print_timestamp) Mail remove completed"
