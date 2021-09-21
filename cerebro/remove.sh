#!/bin/bash

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) Cerebro remove started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Delete project cerebro"
oc delete project cerebro

echo
echo ">>>>$(print_timestamp) Wait for Project cerebro deletion"
wait_for_k8s_resource_disappear project/cerebro

echo
echo ">>>>$(print_timestamp) Cerebro remove completed"
