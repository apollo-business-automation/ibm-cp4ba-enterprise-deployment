#!/bin/bash

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) OpenLDAP + phpLDAPadmin remove started"

echo
echo ">>>>Source internal variables"
. ../internal-variables.sh

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Delete project openldap"
oc delete project openldap

echo
echo ">>>>$(print_timestamp) Wait for Project openldap deletion"
wait_for_k8s_resource_disappear project/openldap

echo
echo ">>>>$(print_timestamp) Delete helm repo"
helm repo remove helm-openldap

echo
echo ">>>>$(print_timestamp) OpenLDAP + phpLDAPadmin remove completed"
