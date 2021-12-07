#!/bin/bash

# Based on https://gitea.com/gitea/helm-chart

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
echo ">>>>$(print_timestamp) Gitea install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Create Project"
oc new-project gitea

echo
echo ">>>>$(print_timestamp) Add privileged access"
# Gitea contains fsGroup: 1000 which cannot be configured from outside, and needs privileged access
oc adm policy add-scc-to-user privileged -z default

echo
echo ">>>>$(print_timestamp) Add helmchart"
helm repo add gitea-charts https://dl.gitea.io/charts/
helm repo update

echo
echo ">>>>$(print_timestamp) Update gitea helm values"
sed -f - values.yaml > values.target.yaml << SED_SCRIPT
s|{{LDAP_HOSTNAME}}|${LDAP_HOSTNAME}|g
s|{{OCP_APPS_ENDPOINT}}|${OCP_APPS_ENDPOINT}|g
s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g
s|{{STORAGE_CLASS_NAME}}|${STORAGE_CLASS_NAME}|g
SED_SCRIPT

echo
echo ">>>>$(print_timestamp) Install helm release"
helm install gitea gitea-charts/gitea --values values.target.yaml --version ${GITEA_CHART_VERSION}

echo
echo ">>>>$(print_timestamp) Create gitea Route"
oc create route edge gitea --hostname=gitea.${OCP_APPS_ENDPOINT} \
--service=gitea-http --insecure-policy=Redirect --cert=../global-ca/wildcard.crt \
--key=../global-ca/wildcard.key --ca-cert=../global-ca/global-ca.crt

echo
echo ">>>>$(print_timestamp) Wait for gitea pod to be Ready"
wait_for_k8s_resource_condition pod/gitea-0 Ready

echo
echo ">>>>$(print_timestamp) Sync LDAP users"
curl --insecure --request POST "https://gitea.${OCP_APPS_ENDPOINT}/api/v1/admin/cron/sync_external_users" \
--header  "Accept: application/json" \
--user "giteaadmin:${UNIVERSAL_PASSWORD}"

echo
echo ">>>>$(print_timestamp) Gitea install completed"
