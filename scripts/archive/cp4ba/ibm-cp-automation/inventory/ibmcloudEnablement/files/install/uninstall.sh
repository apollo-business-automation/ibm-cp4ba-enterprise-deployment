# set -x

base_dir="$(cd $(dirname $0) && pwd)"
casepath="${base_dir}/../../../.."

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
#   NAME: cp4a
#   DESCRIPTION:  Unzip cert-k8s-21.0.1.tar
# ===============================================================================
function unzip_cert_k8s(){
  local inventoryOfsdk="cp4aOperatorSdk"
  local cert_k8s="${casepath}"/inventory/"${inventoryOfsdk}"/files/deploy/crs/cert-k8s-21.0.2.tar
  rm -rf $base_dir/cert-kubernetes
  tar -xvzf $cert_k8s -C $base_dir
  export cert_k8s_path="${base_dir}/cert-kubernetes"
}

#===  FUNCTION  ================================================================
#   NAME: delete_pvc
#   DESCRIPTION:  delete all pvcs in JOB_NAMESPACE, and wait for Operator PVC is deleted.
# ===============================================================================
function delete_pvc() {
    local maxRetry=20
    oc delete pvc $(oc get pvc -n $JOB_NAMESPACE | awk '{print $1}' | grep -v NAME) -n $JOB_NAMESPACE 2>/dev/null || echo "PVC in ${JOB_NAMESPACE} deleted."
    for ((retry=0;retry<=${maxRetry};retry++)); do        
      isReady=$(oc get pvc -n ${JOB_NAMESPACE} | grep operator-shared-pvc )
      if [[ -z $isReady ]]; then
        echo "[INFO] CP4A operator PVC deleted!"
        break
      else
        if [[ $retry -eq ${maxRetry} ]]; then 
          error_exit "Timeout Waiting for CP4A operator PVC to be removed!"
        else
          echo "[INFO] Waiting for CP4A operator PVC to be removed...."
          sleep 10
          continue
        fi
      fi
    done   
}
#===  FUNCTION  ================================================================
#   NAME: delete_cr
#   DESCRIPTION:  delete Operator CR
# ===============================================================================
function delete_cr() {
  if oc get icp4acluster -n $JOB_NAMESPACE | grep -v "No resources found"; then
    if ! oc delete icp4acluster $(oc get icp4acluster -n $JOB_NAMESPACE | awk '{print $1}' | grep -v NAME) -n $JOB_NAMESPACE; then
      error_exit "Can't delete ICP4ACluster from $JOB_NAMESPACE. Pls do a 'oc get icp4acluster -n $JOB_NAMESPACE' to check its status. "
    fi
  fi
}
#===  FUNCTION  ================================================================
#   NAME: cp4a
#   DESCRIPTION:  install cp4a based on the case inventory
# ===============================================================================
function uninstall_cp4a() {
    oc project $JOB_NAMESPACE
    delete_cr
    unzip_cert_k8s
    
    local inventoryOfcatalog="cp4aOperatorSetup"
    local catalog_group="ibm-cp4a-operator-catalog-group"
    local maxRetry=20
    if [ "${ENVIRONMENT}" == "STAGING" ]; then
      local generic_catalog_source=$cert_k8s_path/descriptors/op-olm/cp4a_catalogsource.yaml
    else
      local generic_catalog_source=$cert_k8s_path/descriptors/op-olm/catalog_source.yaml
    fi

    echo "[INFO] Deleting cluster role binding"
    oc delete clusterrolebinding $JOB_NAMESPACE-cp4a-operator --ignore-not-found=true --wait=true

    echo "[INFO] Deleting Subscriptions"
    oc delete subscription --all -n $JOB_NAMESPACE 
    oc delete subscription --all -n ibm-common-services

    echo "[INFO] Deleting Cluster service versions"
    oc delete csv --all -n $JOB_NAMESPACE 
    oc delete csv --all -n ibm-common-services

    echo "[INFO] Cleanup ibm-common-services"
    oc delete deployment --all -n ibm-commom-services
    oc delete services --all -n ibm-common-services
    
    echo "[INFO] Deleting operator group"
    oc delete og abp-group -n ${JOB_NAMESPACE} --ignore-not-found=true --wait=true
    oc delete og iaf-group -n ${JOB_NAMESPACE} --ignore-not-found=true --wait=true
    oc delete og ibm-cp4a-operator-catalog-group -n ${JOB_NAMESPACE} --ignore-not-found=true --wait=true

    echo "[INFO] Deleting catalog sources"
    oc delete catalogsource abp-operators -n openshift-marketplace --ignore-not-found=true --wait=true 
    oc delete catalogsource iaf-operators -n openshift-marketplace --ignore-not-found=true --wait=true
    oc delete catalogsource iaf-core-operators -n openshift-marketplace --ignore-not-found=true --wait=true
    oc delete catalogsource abp-demo-cartridge -n openshift-marketplace --ignore-not-found=true --wait=true
    oc delete catalogsource iaf-demo-cartridge -n openshift-marketplace --ignore-not-found=true --wait=true
    oc delete catalogsource ibm-cp-data-operator-catalog -n openshift-marketplace --ignore-not-found=true --wait=true
    oc delete catalogsource opencloud-operators -n openshift-marketplace --ignore-not-found=true --wait=true
    oc delete catalogsource ibm-operator-catalog -n openshift-marketplace --ignore-not-found=true --wait=true
    oc delete catalogsource ibm-cp4a-operator-catalog -n openshift-marketplace --ignore-not-found=true --wait=true

    oc get apiservice v1beta1.webhook.certmanager.k8s.io 2>/dev/null
    if [ $? -eq 0 ]; then
      echo "[INFO] Deleting apiservice v1beta1.webhook.certmanager.k8s.io"
      oc delete apiservice v1beta1.webhook.certmanager.k8s.io --ignore-not-found=true --wait=true
    fi

    echo "[INFO] Deleting IAF CRDs"
    oc delete --ignore-not-found $(oc get crd -o name | grep "automation.ibm.com" || echo "crd no-automation-ibm")
    oc delete --ignore-not-found $(oc get crd -o name | grep "ai.ibm.com" || echo "crd no-ai-ibm")

   for ((retry=0;retry<=${maxRetry};retry++)); do        
      echo "[INFO] Waiting for CP4A operator pod to be removed...."         
       
      isReady=$(oc get pod -n "$JOB_NAMESPACE" | grep ibm-cp4a-operator )
      if [[ -z $isReady ]]; then
        echo "[INFO] CP4A operator deleted!"
        break
      else
        if [[ $retry -eq ${maxRetry} ]]; then 
          error_exit "[INFO] Timeout Waiting for CP4A operator to be removed!"
        else
          sleep 30
          continue
        fi
      fi
    done   

    echo "delete IAF CRDs"
    oc delete --ignore-not-found $(oc get crd -o name | grep "automation.ibm.com" || echo "crd no-automation-ibm")
    oc delete --ignore-not-found $(oc get crd -o name | grep "ai.ibm.com" || echo "crd no-ai-ibm")

    kubectl delete secret -n $JOB_NAMESPACE admin.registrykey 2>/dev/null || true
    kubectl delete secret -n openshift-marketplace ibm-entitlement-key 2>/dev/null || true
    kubectl delete clusterrole $(oc get clusterrole --no-headers | grep cp4a | awk '{print $1}')

    # echo "Deleting zen client"
    # oc delete clients zenclient-${JOB_NAMESPACE} 
    # echo "Wait 10 seconds"
    # sleep 10

    echo "Deleting common service IAM rolebinding"
    oc delete zenservice iaf-zen-cpdservice --ignore-not-found=true --wait=true
    for i in `oc get rolebindings.authorization.openshift.io --no-headers|awk '{print $1}'`;do oc patch rolebindings.authorization.openshift.io/$i -p '{"metadata":{"finalizers":[]}}' --type=merge;oc delete rolebindings.authorization.openshift.io $i --ignore-not-found=true --wait=true;done
    for i in `oc get operandrequest --no-headers -n $JOB_NAMESPACE|awk '{print $1}'`;do oc patch operandrequest/$i -p '{"metadata":{"finalizers":[]}}' --type=merge;oc delete operandrequest $i --ignore-not-found=true --wait=true -n $JOB_NAMESPACE ;done
    for i in `oc get authentications.operator.ibm.com --no-headers|awk '{print $1}'`;do oc patch authentications.operator.ibm.com/$i -p '{"metadata":{"finalizers":[]}}' --type=merge;oc delete authentications.operator.ibm.com $i --ignore-not-found=true --wait=true;done
    for i in `oc get clients.oidc.security.ibm.com --no-headers|awk '{print $1}'`;do oc patch clients.oidc.security.ibm.com/$i -p '{"metadata":{"finalizers":[]}}' --type=merge; oc delete clients.oidc.security.ibm.com $i --ignore-not-found=true --wait=true;done
    for i in `oc get rolebindings.authorization.openshift.io -n ibm-common-services --no-headers|awk '{print $1}'`;do oc patch rolebindings.authorization.openshift.io/$i -p '{"metadata":{"finalizers":[]}}' --type=merge -n ibm-common-services;oc delete rolebindings.authorization.openshift.io $i --ignore-not-found=true --wait=true -n ibm-common-services;done
    for i in `oc get operandrequest -n ibm-common-services --no-headers|awk '{print $1}'`;do oc patch operandrequest/$i -p '{"metadata":{"finalizers":[]}}' --type=merge -n ibm-common-services;oc delete operandrequest $i --ignore-not-found=true --wait=true -n ibm-common-services;done
    for i in `oc get namespacescope -n ibm-common-services --no-headers|awk '{print $1}'`;do oc patch namespacescope/$i -p '{"metadata":{"finalizers":[]}}' --type=merge -n ibm-common-services;oc delete namespacescope $i --ignore-not-found=true --wait=true -n ibm-common-services;done
    for i in `oc get operandbindinfo -n ibm-common-services --no-headers|awk '{print $1}'`;do oc patch operandbindinfo/$i -p '{"metadata":{"finalizers":[]}}' --type=merge -n ibm-common-services;oc delete operandbindinfo $i --ignore-not-found=true --wait=true -n ibm-common-services;done
    for i in `oc get policycontroller.operator.ibm.com -n ibm-common-services --no-headers|awk '{print $1}'`;do oc patch policycontroller.operator.ibm.com/$i -p '{"metadata":{"finalizers":[]}}' --type=merge -n ibm-common-services;oc delete policycontroller.operator.ibm.com $i --ignore-not-found=true --wait=true -n ibm-common-services;done
    for i in `oc get authentications.operator.ibm.com -n ibm-common-services --no-headers|awk '{print $1}'`;do oc patch authentications.operator.ibm.com/$i -p '{"metadata":{"finalizers":[]}}' --type=merge -n ibm-common-services;oc delete authentications.operator.ibm.com $i --ignore-not-found=true --wait=true -n ibm-common-services;done
    for i in `oc get nginxingresses.operator.ibm.com -n ibm-common-services --no-headers|awk '{print $1}'`;do oc patch nginxingresses.operator.ibm.com/$i -p '{"metadata":{"finalizers":[]}}' --type=merge -n ibm-common-services;oc delete nginxingresses.operator.ibm.com $i --ignore-not-found=true --wait=true -n ibm-common-services;done
    for i in `oc get oidcclientwatcher.operator.ibm.com -n ibm-common-services --no-headers|awk '{print $1}'`;do oc patch oidcclientwatcher.operator.ibm.com/$i -p '{"metadata":{"finalizers":[]}}' --type=merge -n ibm-common-services;oc delete oidcclientwatcher.operator.ibm.com $i --ignore-not-found=true --wait=true -n ibm-common-services;done
    for i in `oc get oidcclientwatchers.operator.ibm.com -n ibm-common-services --no-headers|awk '{print $1}'`;do oc patch oidcclientwatchers.operator.ibm.com/$i -p '{"metadata":{"finalizers":[]}}' --type=merge -n ibm-common-services;oc delete oidcclientwatchers.operator.ibm.com $i --ignore-not-found=true --wait=true -n ibm-common-services;done
    for i in `oc get commonui.operator.ibm.com -n ibm-common-services --no-headers|awk '{print $1}'`;do oc patch commonui.operator.ibm.com/$i --ignore-not-found=true -p '{"metadata":{"finalizers":[]}}' --type=merge -n ibm-common-services;oc delete commonui.operator.ibm.com $i --ignore-not-found=true --wait=true -n ibm-common-services;done
    for i in `oc get commonui1.operator.ibm.com -n ibm-common-services --no-headers|awk '{print $1}'`;do oc patch commonui1.operator.ibm.com/$i -p '{"metadata":{"finalizers":[]}}' --type=merge -n ibm-common-services;oc delete commonui1.operator.ibm.com $i --ignore-not-found=true --wait=true -n ibm-common-services;done
    for i in `oc get commonwebuis.operator.ibm.com -n ibm-common-services --no-headers|awk '{print $1}'`;do oc patch commonwebuis.operator.ibm.com/$i -p '{"metadata":{"finalizers":[]}}' --type=merge -n ibm-common-services;oc delete commonwebuis.operator.ibm.com $i --ignore-not-found=true --wait=true -n ibm-common-services;done
    for i in `oc get commonwebuis.operators.ibm.com -n ibm-common-services --no-headers|awk '{print $1}'`;do oc patch commonwebuis.operators.ibm.com/$i -p '{"metadata":{"finalizers":[]}}' --type=merge -n ibm-common-services;oc delete commonwebuis.operators.ibm.com $i --ignore-not-found=true --wait=true -n ibm-common-services;done
    for i in `oc get platformapis.operator.ibm.com -n ibm-common-services --no-headers|awk '{print $1}'`;do oc patch platformapis.operator.ibm.com/$i -p '{"metadata":{"finalizers":[]}}' --type=merge -n ibm-common-services;oc delete platformapis.operator.ibm.com $i -n ibm-common-services;done

    oc get apiservice v1beta1.webhook.certmanager.k8s.io 2>/dev/null
    if [ $? -eq 0 ]; then
      echo "delete apiservice v1beta1.webhook.certmanager.k8s.io"
      oc delete apiservice v1beta1.webhook.certmanager.k8s.io
    fi

    oc get apiservice v1.metering.ibm.com 2>/dev/null
    if [ $? -eq 0 ]; then
      echo "delete apiservice v1.metering.ibm.com"
      oc delete apiservice v1.metering.ibm.com
    fi

    echo "Delete common service webhook"
    oc delete ValidatingWebhookConfiguration cert-manager-webhook --ignore-not-found
    oc delete MutatingWebhookConfiguration cert-manager-webhook ibm-common-service-webhook-configuration namespace-admission-config --ignore-not-found

    delete_pvc

    echo "[INFO] Deleting project ibm-common-services"
    oc delete project ibm-common-services
    echo "[INFO] Wait until project ibm-common-services is completely deleted."
    count=0
    while :
    do
      oc get project ibm-common-services 2>/dev/null
      if [[ $?>0 ]]; then
        echo "[INFO] Project ibm-common-services deletion successful"
      break
      else
        ((count+=1))
      if (( count <= 36 )); then
        echo "[INFO] Waiting for project ibm-common-services to be terminated.  Recheck in 10 seconds"
        sleep 10     
      else
        echo "[INFO] Deleting project ibm-common-services is taking too long and giving up"
        exit 1
      fi
      fi
    done

    echo "[INFO] Deleting project ${JOB_NAMESPACE}"
    oc project default
    oc delete project $JOB_NAMESPACE
    echo "[INFO] Wait until project ${JOB_NAMESPACE} is completely deleted."
    count=0
    while :
    do
      oc get project $JOB_NAMESPACE 2>/dev/null
      if [[ $?>0 ]]; then
        echo "[INFO] Project $JOB_NAMESPACE deletion successful"
      break
      else
        ((count+=1))
      if (( count <= 36 )); then
        echo "[INFO] Waiting for project $JOB_NAMESPACE to be terminated.  Recheck in 10 seconds"
        sleep 10     
      else
        echo "[INFO] Deleting project $JOB_NAMESPACE is taking too long and giving up"
        exit 1
      fi
      fi
    done
    
    echo "[INFO] Done uninstalling CP4A"
}

uninstall_cp4a