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
echo ">>>>$(print_timestamp) Nexus remove started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Switch Project"
oc project nexus

echo
echo ">>>>$(print_timestamp) Delete NexusRepo instance"
oc delete NexusRepo/nexusrepo

echo
echo ">>>>$(print_timestamp) Wait for NexusRepo nexusrepo deletion"
wait_for_k8s_resource_disappear NexusRepo/nexusrepo

echo
echo ">>>>$(print_timestamp) Delete project nexus"
oc delete project nexus

echo
echo ">>>>$(print_timestamp) Wait for Project nexus deletion"
wait_for_k8s_resource_disappear project/nexus

echo
echo ">>>>$(print_timestamp) Restore original maven settings.xml"
mv -f ~/.m2/settings.xml.bak ~/.m2/settings.xml

echo
echo ">>>>$(print_timestamp) Nexus remove completed"
