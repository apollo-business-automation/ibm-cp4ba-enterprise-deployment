#!/bin/bash

#Based on https://www.ibm.com/docs/en/cpfs?topic=issues-uninstallation-is-not-successful

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
echo ">>>>$(print_timestamp) CPFS remove started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Force delete Project ibm-common-services"
./force-uninstall.sh -n ibm-common-services

echo
echo ">>>>$(print_timestamp) Force delete Project common-service"
./force-uninstall.sh -n common-service

echo
echo ">>>>$(print_timestamp) Switch to Project openshift-monitoring"
oc project openshift-monitoring

echo
echo ">>>>$(print_timestamp) Revert OCP user defined monitoring"
all_mode=`oc get cm cluster-monitoring-config -o json | grep "automode: all"`
if [[ ! -z "$all_mode" ]]; then
  oc delete cm cluster-monitoring-config
fi

inc_mode=`oc get cm cluster-monitoring-config -o json | grep "automode: inc"`
if [[ ! -z "$inc_mode" ]]; then
  oc get cm cluster-monitoring-config -o json | sed 's|"config.yaml": "automode: inc\\nenableUserWorkload: true\\n|"config.yaml": "|g' | oc apply -f - 
fi

echo
echo ">>>>$(print_timestamp) CPFS remove completed"
