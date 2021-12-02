#!/bin/bash

# Based on https://www.ibm.com/docs/en/cpfs
# Based on https://www.ibm.com/docs/en/cpfs?topic=online-installing-foundational-services-by-using-cli  

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
echo ">>>>$(print_timestamp) CPFS install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Switch to Project openshift-monitoring"
oc project openshift-monitoring

echo
echo ">>>>$(print_timestamp) Set OCP user defined monitoring"
CM=`oc get cm cluster-monitoring-config`
if [ -z "$CM" ]; then
  echo "CM not present, creating"
  touch cluster-monitoring-config.yaml
  yq w -i cluster-monitoring-config.yaml enableUserWorkload "true"
  yq w -i cluster-monitoring-config.yaml automode "all"
  oc create cm cluster-monitoring-config --from-file=config.yaml=cluster-monitoring-config.yaml
else
  echo "CM present, checking for enableUserWorkload key"
  PRESENT=`oc get cm cluster-monitoring-config -o jsonpath='{.data.config\.yaml}' | yq r - enableUserWorkload`
  if [ -z "$PRESENT" ]; then
    echo "CM present, enableUserWorkload key not present, adding"  
    oc get cm cluster-monitoring-config -o json | sed 's|"config.yaml": "|"config.yaml": "automode: inc\\nenableUserWorkload: true\\n|g' | oc apply -f - 
  fi
fi

echo
echo ">>>>$(print_timestamp) Create Projects"
oc new-project common-service
oc new-project ibm-common-services

echo
echo ">>>>$(print_timestamp) Switch to Project common-service"
oc project common-service

echo
echo ">>>>$(print_timestamp) Add OperatorGroup"
oc apply -f operatorgroup.yaml

echo
echo ">>>>$(print_timestamp) Add Subscription"
oc apply -f subscription.yaml

echo
echo ">>>>$(print_timestamp) Switch to Project ibm-common-services"
oc project ibm-common-services

echo
echo ">>>>$(print_timestamp) Wait for Operator Deployment to be Available"
wait_for_k8s_resource_condition deployment/operand-deployment-lifecycle-manager Available ${DEFAULT_ATTEMPTS_1} ${DEFAULT_DELAY_1}

echo
echo ">>>>$(print_timestamp) Wait for OperandConfig CRD to be Established"
wait_for_k8s_resource_condition CustomResourceDefinition/operandconfigs.operator.ibm.com Established

echo
echo ">>>>$(print_timestamp) Wait for OperandConfig instance Ready state"
wait_for_k8s_resource_condition_generic OperandConfig/common-service ".status.phase" Initialized

echo
echo ">>>>$(print_timestamp) Patch authentication object to customize admin username"
# Based on https://www.ibm.com/docs/en/cpfs?topic=services-configuring-foundational-by-using-custom-resource#default-admin for admin username
INDEX=`oc get operandconfig common-service -o json | jq '[.spec.services[] | .name == "ibm-iam-operator"] | index(true)'`
oc patch operandconfig common-service --type json -p '[{"op":"replace","path":"/spec/services/'$INDEX'/spec/authentication/config", "value":{}}]'

echo
echo ">>>>$(print_timestamp) Change admin username"
oc patch operandconfig common-service --type json -p '[{"op":"replace","path":"/spec/services/'$INDEX'/spec/authentication/config/defaultAdminUser", "value":"cpfsadmin"}]'

echo
echo ">>>>$(print_timestamp) Apply OperandRequest instance"
oc apply -f operandrequest.yaml

echo
echo ">>>>$(print_timestamp) Wait for OperandRequest instance Running phase"
wait_for_k8s_resource_condition_generic OperandRequest/common-service ".status.phase" Running

echo
echo ">>>>$(print_timestamp) Switch to Project kube-public"
oc project kube-public

echo
echo ">>>>$(print_timestamp) Wait for IAM Ready status as an indicator that CPFS is installed"
wait_for_k8s_resource_condition_generic ConfigMap/ibm-common-services-status ".data.iamstatus" Ready ${DEFAULT_ATTEMPTS_2} ${DEFAULT_DELAY_2}

echo
echo ">>>>$(print_timestamp) Switch to Project ibm-common-services"
oc project ibm-common-services

echo
echo ">>>>$(print_timestamp) Apply custom certificate for License Service"
# Based on https://www.ibm.com/docs/en/cpfs?topic=operator-using-custom-certificates
oc create secret tls ibm-licensing-certs --key ../global-ca/wildcard.key --cert ../global-ca/wildcard.crt
oc patch IBMLicensing instance --type json -p '[{"op":"replace","path":"/spec/httpsCertsSource", "value":"custom"}]'

echo
echo ">>>>$(print_timestamp) Add License Service Reporter"
# Based on Based on https://www.ibm.com/docs/en/cpfs?topic=reporter-deploying-license-service
oc apply -f ibmlicenseservicereporter.yaml

echo
echo ">>>>$(print_timestamp) Configure License Service Reporter"
INDEX=`oc get operandconfig common-service -o json | jq '[.spec.services[] | .name == "ibm-licensing-operator"] | index(true)'`	
oc patch operandconfig common-service --type json -p '[{"op":"replace","path":"/spec/services/'$INDEX'/spec/IBMLicenseServiceReporter", "value":{}}]'

echo
echo ">>>>$(print_timestamp) Wait for license reporter Deployment to be Available"
wait_for_k8s_resource_condition deployment/ibm-license-service-reporter-instance Available

echo
echo ">>>>$(print_timestamp) Switch Ingress certificate mode & delete artifacts"
# Based on https://www.ibm.com/docs/en/cpfs?topic=operator-replacing-foundational-services-endpoint-certificates

echo
echo ">>>>$(print_timestamp) Wait for management ingress operator Deployment to be Available"
wait_for_k8s_resource_condition deployment/ibm-management-ingress-operator Available

echo
echo ">>>>$(print_timestamp) Patch certificate settings"
oc patch managementingress default --type merge --patch '{"spec":{"ignoreRouteCert":true}}'

echo
echo ">>>>$(print_timestamp) Wait for log occurence of Not watching certs"
wait_for_k8s_log_occurrence deployment/ibm-management-ingress-operator "Not watching certificate: route-cert, IgnoreRouteCert is true." ${DEFAULT_ATTEMPTS_3} ${DEFAULT_DELAY_3}

echo
echo ">>>>$(print_timestamp) Replace certificate"
oc delete certificate.certmanager.k8s.io route-cert
sleep 30
oc delete secret route-tls-secret
oc create secret generic route-tls-secret --from-file=ca.crt=../global-ca/global-ca.crt --from-file=tls.crt=../global-ca/wildcard.crt --from-file=tls.key=../global-ca/wildcard.key
oc delete secret ibmcloud-cluster-ca-cert
sleep 30
oc delete pod -l app=auth-idp

echo
echo ">>>>$(print_timestamp) Wait for IAM to be Available"
wait_for_k8s_resource_condition deployment/auth-idp Available

echo
echo ">>>>$(print_timestamp) Add cloudctl command"
#Based on https://www.ibm.com/docs/en/cpfs?topic=mycc-installing-cloudctl
curl -k -o cloudctl https://cp-console.${OCP_APPS_ENDPOINT}/api/cli/cloudctl-linux-amd64
chmod u+x cloudctl

echo
echo ">>>>$(print_timestamp) Change cpfsadmin user password"
# Based on https://www.ibm.com/docs/en/cpfs?topic=configurations-changing-cluster-administrator-access-credentials#pwd  
./cloudctl login -a https://cp-console.${OCP_APPS_ENDPOINT} -u cpfsadmin -p `oc get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 --decode` -n ibm-common-services
./cloudctl pm update-secret ibm-common-services platform-auth-idp-credentials -d admin_password=${UNIVERSAL_PASSWORD} -f
./cloudctl logout

if [[ -z "$CONTAINER_RUN_MODE" ]]; then
  echo
  echo ">>>>$(print_timestamp) OC Relogin"
  if [[ ! -z "$OCP_CLUSTER_TOKEN" ]]; then
    oc login --server="${OCP_API_ENDPOINT}" --token="${OCP_CLUSTER_TOKEN}"
  else
    oc login --server="${OCP_API_ENDPOINT}" -u "${OCP_CLUSTER_ADMIN}" -p "${OCP_CLUSTER_ADMIN_PASSWORD}"
  fi
fi
oc project ibm-common-services

echo
echo ">>>>$(print_timestamp) Wait for IAM to be Available"
wait_for_k8s_resource_condition deployment/auth-pdp Available
wait_for_k8s_resource_condition deployment/auth-pap Available
wait_for_k8s_resource_condition deployment/auth-idp Available

echo
echo ">>>>$(print_timestamp) Connect IAM to LDAP"
# Based on https://www.ibm.com/docs/en/cloud-paks/1.0?topic=users-configuring-ldap-connection

# Get access token for administrative user
ACCESS_TOKEN=`curl -k -X POST -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" \
-d "grant_type=password&username=cpfsadmin&password=${UNIVERSAL_PASSWORD}&scope=openid" \
https://cp-console.${OCP_APPS_ENDPOINT}/idprovider/v1/auth/identitytoken \
| jq -r '.access_token'`

# Add LDAP connection
curl -k -X POST --header "Authorization: bearer $ACCESS_TOKEN" \
--header 'Content-Type: application/json' \
-d '{"LDAP_ID": "LDAP", "LDAP_URL": "ldap://'${LDAP_HOSTNAME}':389", 
"LDAP_BASEDN": "dc=cp", "LDAP_BINDDN": "cn=admin,dc=cp", 
"LDAP_BINDPASSWORD": "'$(echo -n ${UNIVERSAL_PASSWORD} | base64)'", "LDAP_TYPE": "Custom", 
"LDAP_USERFILTER": "(&(uid=%v)(objectclass=inetOrgPerson))", 
"LDAP_GROUPFILTER": "(&(cn=%v)(objectclass=groupOfNames))", 
"LDAP_USERIDMAP": "*:cn","LDAP_GROUPIDMAP":"*:cn", 
"LDAP_GROUPMEMBERIDMAP": "groupOfNames:member"}' \
"https://cp-console.${OCP_APPS_ENDPOINT}/idmgmt/identity/api/v1/directory/ldap/onboardDirectory"

echo
echo ">>>>$(print_timestamp) CPFS install completed"
