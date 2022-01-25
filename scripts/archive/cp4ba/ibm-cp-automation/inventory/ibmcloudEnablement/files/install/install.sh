# set -x

# Change this for target tag before release, when testing on STAGING env and replace_tag=true, it will use this tag in the generated CR.
# This will be ignored for PRODUCTION env.
image_tag="2103.rc3" 
replace_tag="true" # Set if fase for GM stage

base_dir="$(cd $(dirname $0) && pwd)"

# LOGIN
printf "%s" "$KUBECONFIG_VALUE" > ./kubeconfig.json
printf "%s" "$KUBECONFIG_PEM_VALUE" > ./ca.pem

# Clean up pem file contents
sed -i 's/\\n/\n/g' ca.pem
sed -i 's/\"//g' ca.pem

#===  FUNCTION  ================================================================
#   NAME: error_exit
#   DESCRIPTION:  function to exit with custom error message
#   PARAMETERS:
#       1: message to error to stdout
# ===============================================================================
function error_exit() {
    echo >&2 "[ERROR] $1"
    exit 1
}

#===  FUNCTION  ================================================================
#   NAME: validate_file_exists
#   DESCRIPTION:  validate if a path given contains a valid file
#   PARAMETERS:
#       1: filepath
# ===============================================================================
function validate_file_exists() {
  local file=$1
  [[ ! -f ${file} ]] && { error_exit "${file} not found, exiting deployment."; }
}

# Arguments
export NAMESPACE=${JOB_NAMESPACE}
export DOCKER_USERNAME=${DOCKER_REGISTRY_USER:-ekey}
export STORAGE_CLASS="ibmc-file-gold-gid"
# export ENVIRONMENT=$deployType

echo $ENVIRONMENT

if [ "${ENVIRONMENT}" == "STAGING" ]; then
  export DOCKER_REGISTRY="cp.stg.icr.io"
  export USE_STAGE="true" #used by user script
else
  export DOCKER_REGISTRY="cp.icr.io"
  export USE_STAGE="false"
fi

if [ -z "${DOCKER_REGISTRY_PASS}" ]; then
  error_exit "entitlement licensing not found"
else
  export DOCKER_REGISTRY_PASS=${DOCKER_REGISTRY_PASS}
fi

base_dir="$(cd $(dirname $0) && pwd)"
casepath="${base_dir}/../../../.."

#===  FUNCTION  ================================================================
#   NAME: cp4a
#   DESCRIPTION:  Unzip cert-k8s-21.0.1.tar
# ===============================================================================
function unzip_cert_k8s(){
  local inventoryOfsdk="cp4aOperatorSdk"
  local cert_k8s="${casepath}"/inventory/"${inventoryOfsdk}"/files/deploy/crs/cert-k8s-21.0.3.tar
  rm -rf $base_dir/cert-kubernetes
  tar -xvzf $cert_k8s -C $base_dir
  export cert_k8s_path="${base_dir}/cert-kubernetes"
}

#===  FUNCTION  ================================================================
#   NAME: error_exit
#   DESCRIPTION:  Create PVC for CP4A Operator
#   PARAMETERS:
#       1: message to error to stdout
# ===============================================================================
function pre_req(){
  # curl '-#' -fL -LO -o ${base_dir}/oc.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/oc/4.6/linux/oc.tar.gz
  # tar zxvf ${base_dir}/oc.tar.gz
  # chmod a+x ${base_dir}/oc
  # mv ${base_dir}/oc /home/appuser/bin
  oc version

  echo -e "\x1B[1m[INFO] Applying no_root_squash for demo DB2 deployment on ROKS using CLI.\x1B[0m"
  oc get no -l node-role.kubernetes.io/worker --no-headers -o name | xargs -I {} --  oc debug {} -- chroot /host sh -c 'grep "^Domain = slnfsv4.coms" /etc/idmapd.conf || ( sed -i "s/.*Domain =.*/Domain = slnfsv4.com/g" /etc/idmapd.conf; nfsidmap -c; rpc.idmapd )'

  unzip_cert_k8s

  # # apply cluster role and cluster role binding
  # echo -e "\x1B[1m[INFO] Applying cluster role and cluster role binding.\x1B[0m"
  # local cluster_role=$cert_k8s_path/descriptors/cluster_role.yaml
  # local cluster_role_binding=$cert_k8s_path/descriptors/cluster_role_binding.yaml
  # sed -i "s/<NAMESPACE>/${JOB_NAMESPACE}/g" $cluster_role_binding
  # oc apply -f $cluster_role -n $JOB_NAMESPACE
  # oc apply -f $cluster_role_binding -n $JOB_NAMESPACE

  # create service account
  oc apply -f $base_dir/service-account-for-demo.yaml -n $JOB_NAMESPACE
  oc adm policy add-scc-to-user anyuid -z ibm-cp4ba-anyuid -n $JOB_NAMESPACE
  oc adm policy add-scc-to-user privileged -z ibm-cp4ba-privileged -n $JOB_NAMESPACE

  # create Operator PVC
  echo -e "\x1B[1m[INFO] Creating Operator PVC.\x1B[0m"
  local pvc_file=$cert_k8s_path/descriptors/operator-shared-pvc.yaml
  sed -i "s/<StorageClassName>/${STORAGE_CLASS}/g" $pvc_file
  sed -i "s/<Fast_StorageClassName>/${STORAGE_CLASS}/g" $pvc_file
  oc apply -f $pvc_file -n ${JOB_NAMESPACE}

  # Check Operator Persistent Volume status every 5 seconds (max 10 minutes) until allocate.
  ATTEMPTS=0
  TIMEOUT=60
  printf "\n"
  echo -e "\x1B[1m[INFO] Waiting for the persistent volumes to be ready...\x1B[0m"
  until oc get pvc -n ${JOB_NAMESPACE} | grep operator-shared-pvc | grep -q -m 1 "Bound" || [ $ATTEMPTS -eq $TIMEOUT ]; do
      ATTEMPTS=$((ATTEMPTS + 1))
      echo -e "......"
      sleep 10
      if [ $ATTEMPTS -eq $TIMEOUT ] ; then
          echo -e "\x1B[1;31m [INFO] Failed to allocate the persistent volumes!\x1B[0m"
          echo -e "\x1B[1;31m [INFO] Run the following command to check the claim 'oc describe pvc operator-shared-pvc'\x1B[0m"
          exit 1
      fi
  done
  if [ $ATTEMPTS -lt $TIMEOUT ] ; then
          echo -e "\x1B[1m[INFO] Done\x1B[0m"
  fi
}

#===  FUNCTION  ================================================================
#   NAME: run
#   DESCRIPTION:  run a command to check for errors and exit if failed
#   PARAMETERS:
#       1: command to be executed
#       2: operation being executed, to aid error log output
# ===============================================================================
function run(){
  local cmd=$1
  local operation=$2
  if ! bash $cmd; then
    error_exit "$operation failed"
  fi
}

#===  FUNCTION  ================================================================
#   NAME: setEntitlementSecret
#   DESCRIPTION:  set the entitlement key secret
# ===============================================================================
function setEntitlementSecret() {
  local entitlementUser="$DOCKER_REGISTRY_USER"
  local entitlementKey="$DOCKER_REGISTRY_PASS"
  # local entitlementRepo="cp.stag.icr.io"
  echo "[INFO] Use $DOCKER_REGISTRY"
  echo "[INFO] Use $ENVIRONMENT"
  # Create secret for Operator image
  sc=$(kubectl get secret -n "$NAMESPACE" admin.registrykey 2>/dev/null)
  if [ "X$sc" != "X" ]; then
     kubectl delete secret -n "$NAMESPACE" admin.registrykey
  fi
  
  if ! kubectl create secret docker-registry admin.registrykey -n "$NAMESPACE" \
  --docker-server="$DOCKER_REGISTRY" "--docker-username=${entitlementUser}" \
  "--docker-password=${entitlementKey}";
  then error_exit "secret admin.registrykey created in $NAMESPACE"
  fi

  # Create secret for catalog index image
  sc=$(kubectl get secret -n openshift-marketplace ibm-entitlement-key 2>/dev/null)
  if [ "X$sc" != "X" ]; then
     kubectl delete secret -n openshift-marketplace ibm-entitlement-key
  fi

  if ! kubectl create secret docker-registry ibm-entitlement-key -n openshift-marketplace \
  --docker-server="$DOCKER_REGISTRY" "--docker-username=${entitlementUser}" \
  "--docker-password=${entitlementKey}";
  then error_exit "secret ibm-entitlement-key created in openshift-marketplace"
  fi

  if ! kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "ibm-entitlement-key"}]}' -n openshift-marketplace; then
    error_exit "Can't add secret ibm-entitlement-key to default service account in openshift-marketplace!"
  fi

}

#===  FUNCTION  ================================================================
#   NAME: copy_jdbc
#   DESCRIPTION: copy jdbc driver into Operator pod
# ===============================================================================
function copy_jdbc() {
  podname=$(oc get pod -n "$NAMESPACE" --no-headers | grep ibm-cp4a-operator | awk '{print $1}')
  
  if [[ $(oc cp ${base_dir}/jdbc ${podname}:/opt/ansible/share -n ${JOB_NAMESPACE} ) -eq 0 ]]; then
    echo "[INFO] Copied jdbc driver into Operator pod!"
  else 
    error_exit "Failed to copy jdbc driver into Operator pod!"
  fi
}

#===  FUNCTION  ================================================================
#   NAME: cp4a
#   DESCRIPTION:  install cp4a based on the case inventory
# ===============================================================================
function install_cp4a() {
    pre_req
    setEntitlementSecret
    local inventoryOfOperator="cp4aOperator"
    local inventoryOfcatalog="cp4aOperatorSetup"
    local online_source="ibm-cp4a-operator-catalog"
    local maxRetry=20

    local generic_catalog_source=$cert_k8s_path/descriptors/op-olm/catalog_source.yaml
    local dev_catalog_source=$cert_k8s_path/descriptors/op-olm/cp4a_catalogsource.yaml
    local operator_group=$cert_k8s_path/descriptors/op-olm/operator_group.yaml
    local subscription=$cert_k8s_path/descriptors/op-olm/subscription.yaml
    
    validate_file_exists "$generic_catalog_source"
    validate_file_exists "$dev_catalog_source"
    validate_file_exists "$operator_group"
    validate_file_exists "$subscription"

    # Apply cp4a_catalogsource.yaml for staging env, catalog_source.yaml for production env.
    if [ "${ENVIRONMENT}" == "STAGING" ]; then
        sed <"${dev_catalog_source}" "s|REPLACE_NAMESPACE|${NAMESPACE}|g" | oc apply -f -
        if [ $? -eq 0 ]; then
          echo "[INFO] ibm operator catalog source created!"
        else
          error_exit "Generic Operator catalog source creation failed"
        fi
    else
        sed <"${generic_catalog_source}" "s|REPLACE_NAMESPACE|${NAMESPACE}|g" | oc apply -f -
        if [ $? -eq 0 ]; then
          echo "[INFO] ibm operator catalog source created!"
        else
          error_exit "Generic Operator catalog source creation failed"
        fi
    fi

    if [[ $(oc get og -n "${NAMESPACE}" -o=go-template --template='{{len .items}}' ) -gt 0 ]]; then
        echo "[INFO] Found operator group"
        oc get og -n "${NAMESPACE}"
    else
      sed <"${operator_group}" "s|REPLACE_NAMESPACE|${NAMESPACE}|g" | oc apply -f -
      if [ $? -eq 0 ]
         then
         echo "[INFO] CP4A Operator Group Created!"
       else
         error_exit "CP4A Operator Operator Group creation failed"
       fi
    fi

    # sed <"${subscription}" "s|REPLACE_NAMESPACE|${NAMESPACE}|g" | oc apply -f -
    sed -i "s|REPLACE_NAMESPACE|${NAMESPACE}|g" $subscription
    if [ "${ENVIRONMENT}" == "STAGING" ]; then
      sed -i "s/ibm-operator-catalog/ibm-cp4a-operator-catalog/g" $subscription
    fi
    oc apply -f $subscription
    if [ $? -eq 0 ]
        then
        echo "[INFO] CP4A Operator Subscription Created!"
    else
        error_exit "CP4A Operator Subscription creation failed"
    fi

   for ((retry=0;retry<=${maxRetry};retry++)); do        
      echo "[INFO] Waiting for CP4A operator pod initialization"         
       
      isReady=$(oc get pod -n "$NAMESPACE" --no-headers | grep ibm-cp4a-operator | grep "Running")
      if [[ -z $isReady ]]; then
        if [[ $retry -eq ${maxRetry} ]]; then 
          error_exit "Timeout Waiting for CP4A operator to start"
        else
          sleep 30
          continue
        fi
      else
        echo "[INFO] CP4A operator is running $isReady"
        break
      fi
    done
}

#===  FUNCTION  ================================================================
#   NAME: set_domain
#   DESCRIPTION: discover domain when not set
#   PARAMETERS:
# ===============================================================================
function set_domain() {
   if [ ! -z "${domain}" ]; then
     return
   fi

   domain="$(oc get -n openshift-console route console -o jsonpath="{.spec.host}" | sed -e 's/^[^\.]*\.//')"
   if [ "$domain" == "" ]; then
      error_exit "Failed to discover domain"
   fi
   echo "[INFO] Domain is: $domain"
}

#===  FUNCTION  ================================================================
#   NAME: replace_tag
#   DESCRIPTION: replace tags in the final CR, this is to test iteration images before release
#   PARAMETERS:
# ===============================================================================
function replace_tag(){
  sed -i "s/tag: 21.0.2/tag: $image_tag/g" ${base_dir}/generated-cr/ibm_cp4a_cr_final.yaml
  sed -i "s/tag: \"21.0.2\"/tag: $image_tag/g" ${base_dir}/generated-cr/ibm_cp4a_cr_final.yaml
  sed -i "s/ga-556-p8cpe-if001/$image_tag/g" ${base_dir}/generated-cr/ibm_cp4a_cr_final.yaml
  sed -i "s/ga-556-p8css-if001/$image_tag/g" ${base_dir}/generated-cr/ibm_cp4a_cr_final.yaml
  sed -i "s/ga-556-p8cgql-if002/$image_tag/g" ${base_dir}/generated-cr/ibm_cp4a_cr_final.yaml
  sed -i "s/ga-305-cmis-if004/$image_tag/g" ${base_dir}/generated-cr/ibm_cp4a_cr_final.yaml
  sed -i "s/ga-309-tm-if002/$image_tag/g" ${base_dir}/generated-cr/ibm_cp4a_cr_final.yaml
  sed -i "s/ga-309-es-if002/$image_tag/g" ${base_dir}/generated-cr/ibm_cp4a_cr_final.yaml

  sed -i "s/ga-309-icn-if002/$image_tag/g" ${base_dir}/generated-cr/ibm_cp4a_cr_final.yaml
  sed -i "s/ga-521-ier-fp006/$image_tag/g" ${base_dir}/generated-cr/ibm_cp4a_cr_final.yaml
  sed -i "s/ga-4004-iccsap-if003/$image_tag/g" ${base_dir}/generated-cr/ibm_cp4a_cr_final.yaml
  
  sed -i '/shared_configuration/a\    show_sensitive_log: true' ${base_dir}/generated-cr/ibm_cp4a_cr_final.yaml  #CAN BE COMMENTED
  sed -i '/shared_configuration/a\    no_log: false' ${base_dir}/generated-cr/ibm_cp4a_cr_final.yaml  #CAN BE COMMENTED
}

#===  FUNCTION  ================================================================
#   NAME: generate_cr
#   DESCRIPTION: discover domain when not set
#   PARAMETERS:
# ===============================================================================
function generate_cr(){
  set_domain
  INFRA_NAME_ONECLICK=$domain
  source ${base_dir}/cp4a-deployment.sh oneclick
  sed -i '/ibm_license:/a\  request_from_oneclick: false' ${base_dir}/generated-cr/ibm_cp4a_cr_final.yaml
  # sed -i 's/sc_ingress_enable: false/sc_ingress_enable: true/g' ${base_dir}/generated-cr/ibm_cp4a_cr_final.yaml
  if [[ ("${ENVIRONMENT}" == "STAGING") && ("$replace_tag" == "true") ]]; then
    replace_tag
  fi

  cat ${base_dir}/generated-cr/ibm_cp4a_cr_final.yaml
  if ! oc apply -f ${base_dir}/generated-cr/ibm_cp4a_cr_final.yaml -n $NAMESPACE; then
    error_exit "Can't apply ICP4ACluster CR from ${base_dir}/generated-cr/ibm_cp4a_cr_final.yaml!"
  fi
  
  echo -e "\x1B[1mThe deployment will take about 1 - 3 hours to finish depending on your selection. Once you see configmap icp4adeploy-cp4ba-access-info created in the selected project, you can visit your deployment with the URLs in it.\x1B[0m"
  echo -e "\x1B[1mFor details, refer to the troubleshooting section in Knowledge Center here: \x1B[0m"
  echo -e "\x1B[1mhttps://www.ibm.com/support/knowledgecenter/SSYHZ8_21.0.x/com.ibm.dba.install/op_topics/tsk_trbleshoot_operators.html\x1B[0m"
}
install_cp4a
generate_cr
