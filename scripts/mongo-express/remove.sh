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
echo ">>>>$(print_timestamp) Mongo Express remove started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Delete project mongo-express"
oc delete project mongo-express

echo
echo ">>>>$(print_timestamp) Wait for Project mongo-express deletion"
wait_for_k8s_resource_disappear project/mongo-express

echo
echo ">>>>$(print_timestamp) Mongo Express remove completed"
