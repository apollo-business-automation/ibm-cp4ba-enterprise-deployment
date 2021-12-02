#!/bin/bash

# Based on https://www.ibm.com/docs/en/db2/11.5?topic=deployments-db2-red-hat-openshift
# License Based on https://www.ibm.com/docs/en/db2/11.5?topic=updating-managing-licenses

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
echo ">>>>$(print_timestamp) DB2 install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Create Project"
oc new-project db2

if [ "$DEPLOYMENT_PLATFORM" = "ROKS" ]; then
echo
echo ">>>>$(print_timestamp) Update worker nodes on ROKS for DB2 storage"
# Based on https://www.ibm.com/docs/en/db2/11.5?topic=requirements-cloud-file-storage
  oc get no -l node-role.kubernetes.io/worker --no-headers -o name \
  | xargs -I {} --  oc debug {} -- chroot /host sh -c 'grep "^Domain = slnfsv4.coms" /etc/idmapd.conf || ( sed -i "s/.*Domain =.*/Domain = slnfsv4.com/g" /etc/idmapd.conf; nfsidmap -c; rpc.idmapd )'
  sleep 45
fi

echo
echo ">>>>$(print_timestamp) Add OperatorGroup"
oc apply -f operatorgroup.yaml

echo
echo ">>>>$(print_timestamp) Add Subscription"
oc apply -f subscription.yaml

echo
echo ">>>>$(print_timestamp) Wait for InstallPlan to be created"
wait_for_k8s_resource_condition_generic Subscription/db2u-operator ".status.installplan.kind" InstallPlan ${DEFAULT_ATTEMPTS_1} ${DEFAULT_DELAY_1}

echo
echo ">>>>$(print_timestamp) Approve InstallPlan"
install_plan=`oc get subscription db2u-operator -o json | jq -r '.status.installplan.name'`
oc patch installplan ${install_plan} --type merge --patch '{"spec":{"approved":true}}'

echo
echo ">>>>$(print_timestamp) Wait for Operator Deployment to be Available"
wait_for_k8s_resource_condition deployment/db2u-operator-manager Available

echo
echo ">>>>$(print_timestamp) Wait for DB2uCluster CRD to be Established"
wait_for_k8s_resource_condition CustomResourceDefinition/db2uclusters.db2u.databases.ibm.com Established

echo
echo ">>>>$(print_timestamp) Add ICR secret"
oc create secret docker-registry ibm-entitlement-key --docker-username=cp --docker-password="${ICR_PASSWORD}" --docker-server="cp.icr.io"

echo
echo ">>>>$(print_timestamp) Update DB2uCluster CR"
yq w -i db2ucluster.yaml spec.storage[0].spec.storageClassName "${STORAGE_CLASS_NAME}"
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" db2ucluster.yaml

echo
echo ">>>>$(print_timestamp) Add DB2uCluster instance"
# Based on LI at http://www-03.ibm.com/software/sla/sladb.nsf/doclookup/F2925E0D5C24EAB4852586FE0060B3CC?OpenDocument DB2 Standard Edition is a supporting program with limitation of 16 CPU and 128 Memory
oc apply -f db2ucluster.yaml

echo
echo ">>>>$(print_timestamp) Wait for Db2uCluster instance Ready state"
wait_for_k8s_resource_condition_generic Db2uCluster/db2ucluster ".status.state" Ready ${DEFAULT_ATTEMPTS_1} ${DEFAULT_DELAY_1}

echo
echo ">>>>$(print_timestamp) Delete BLUDB"
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
sleep 30 #for db2start to finish
db2 deactivate db BLUDB
db2 force application ALL
sleep 30 #for force aplication to finish
db2 drop db BLUDB
EOSSH

echo
echo ">>>>$(print_timestamp) DB2 install completed"
