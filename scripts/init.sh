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
OCP_APPS_ENDPOINT=`oc get route console -n openshift-console -o json | jq -r '.status.ingress[0].routerCanonicalHostname'`

echo
echo ">>>>$(print_timestamp) Set escaped password"
ESCAPED_UNIVERSAL_PASSWORD=$(printf '%s\n' "${UNIVERSAL_PASSWORD}" | sed -e 's/[\|&]/\\&/g')
