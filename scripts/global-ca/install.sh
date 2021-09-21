#!/bin/bash

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) Global CA install started"

echo
echo ">>>>Init env"
. ../init.sh

if [[ $GLOBAL_CA_PROVIDED == "false" ]]; then
  echo
  echo ">>>>$(print_timestamp) Generate certificate key"
  openssl genrsa -out global-ca.key 4096

  echo
  echo ">>>>$(print_timestamp) Generate certificate crt"
  openssl req -x509 -new -nodes -key global-ca.key -sha256 -days 36500 -out global-ca.crt \
  -subj "/CN=Global CA"
  if [[ $CONTAINER_RUN_MODE == "true" ]]; then
    oc project automagic
    oc create secret generic global-ca --from-file=global-ca.crt=global-ca.crt --from-file=global-ca.key=global-ca.key -o yaml --dry-run=client | oc apply -f -
  fi  
else
  echo
  echo ">>>>$(print_timestamp) Global CA has been provided"
fi

echo
echo ">>>>$(print_timestamp) Generate wildcard certificate"
openssl genrsa -out wildcard.key 2048

openssl req -new -sha256 \
-key wildcard.key \
-subj "/CN=Wildcard" \
-addext "subjectAltName=DNS:*.${OCP_APPS_ENDPOINT}" \
-out wildcard.csr

openssl x509 -req -extfile <(printf "subjectAltName=DNS:*.${OCP_APPS_ENDPOINT}") -days 36500 \
-in wildcard.csr -CA global-ca.crt -CAkey global-ca.key -CAcreateserial -out wildcard.crt

echo
echo ">>>>$(print_timestamp) Global CA install completed"
