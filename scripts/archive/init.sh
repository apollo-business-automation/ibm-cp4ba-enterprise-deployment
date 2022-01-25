#!/bin/bash

if [[ -z "$CONTAINER_RUN_MODE" ]]; then
  echo
  echo ">>>>$(print_timestamp) OC login"
  if [[ ! -z "$OCP_CLUSTER_TOKEN" ]]; then
    oc login --server="${OCP_API_ENDPOINT}" --token="${OCP_CLUSTER_TOKEN}"
  else
    oc login --server="${OCP_API_ENDPOINT}" -u "${OCP_CLUSTER_ADMIN}" -p "${OCP_CLUSTER_ADMIN_PASSWORD}"
  fi
fi

echo
echo ">>>>$(print_timestamp) Set OCP apps endpoint"
# Based on https://docs.openshift.com/container-platform/4.8/networking/ingress-operator.html
OCP_APPS_ENDPOINT=`oc get ingress.config.openshift.io cluster -o json | jq -r '.spec.domain'`

echo
echo ">>>>$(print_timestamp) Set escaped password"
ESCAPED_UNIVERSAL_PASSWORD=$(printf '%s\n' "${UNIVERSAL_PASSWORD}" | sed -e 's/[\|&]/\\&/g')
