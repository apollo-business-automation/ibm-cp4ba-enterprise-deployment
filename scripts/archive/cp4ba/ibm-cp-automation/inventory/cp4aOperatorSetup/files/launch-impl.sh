# (C) Copyright IBM Corp. 2020  All Rights Reserved.
#
# This script implements/overrides the abstract functions defined in launch.sh interface

caseName="ibm-cp-automation"
inventory="cp4aOperatorSetup"

caseCatalogName="ibm-cp4a-operator-catalog"
channelName="v21.3"

foundationCase="ibm-cp-automation-foundation"
foundationInventory="iafOperatorSetup"
#foundationCoreCase="ibm-automation-foundation-core"
#foundationCoreInventory="iafCoreOperatorSetup"

# - variables specific to catalog/operator installation
catalogNamespace="openshift-marketplace"
catalogDigest=":latest"

case_depedencies="ibm-cp-automation-foundation ibm-cp-common-services ibm-bts-bundle"

# parse additional dynamic args
parse_custom_dynamic_args() {
    key=$1
    val=$2
    case $key in
    --systemStatus)
        cr_system_status=$val
        ;;
    esac
}

# returns name of inventory containing setup code, given a CASE name
# this is used during the install of catalog of dependent CASE
dependent_inventory_item() {
    local case_name=$1
    case $case_name in

    ibm-cp-automation-foundation)
        echo "iafOperatorSetup"
        return 0
        ;;
    ibm-cp-common-services)
        echo "ibmCommonServiceOperatorSetup"
        return 0
        ;;
    ibm-bts-bundle)
        echo "btsOperatorSetup"
        return 0
        ;;
    *)
        echo "unknown case: $case_name"
        return 1
        ;;
    esac
}

dependent_case_tgz() {
    local case_name=$1
    local input_dir=$2

    # if there are multiple versions of the case is downloaded ( this happens when same dependency
    # is requested by a different case but with a different version)
    # use the latest version
    # the below command finds files that start with dependent case name, sorts by semver field
    # note that this sort flag is only available on GNU sort ( linux versions)
    case_tgz=$(find "${input_dir}" -name "${case_name}*.tgz" | sort --reverse --version-sort --field-separator="-" | head -n1)

    if [[ -z ${case_tgz} ]]; then
        err_exit "failed to find case tgz for dependent case: ${case_name}"
    fi

    echo "${case_tgz}"
}

install_dependent_catalogs() {

   local dep_case=""

    for dep in $case_depedencies; do
        local dep_case="$(dependent_case_tgz "${dep}" "${inputcasedir}")"

        echo "-------------Installing dependent catalog source: ${dep_case}-------------"

        validate_file_exists "${dep_case}"
        local inventory=""
        inventory=$(dependent_inventory_item "${dep}")

        cloudctl case launch \
            --case "${dep_case}" \
            --namespace "${namespace}" \
            --inventory "${inventory}" \
            --action install-catalog \
            --args "--registry ${registry} --inputDir ${inputcasedir} --recursive ${dryRun:+--dryRun }" \
            --tolerance "${tolerance_val}"

        if [[ $? -ne 0 ]]; then
            err_exit "installing dependent catalog for '${dep_case}' failed"
        fi
    done
}

uninstall_dependent_catalogs() {
    local dep_case=""

    for dep in $case_depedencies; do
        local dep_case="$(dependent_case_tgz "${dep}" "${inputcasedir}")"
        echo "-------------Uninstalling dependent catalog source: ${dep_case}-------------"

        validate_file_exists "${dep_case}"
        local inventory=""
        inventory=$(dependent_inventory_item "${dep}")

        cloudctl case launch \
            --case "${dep_case}" \
            --namespace "${namespace}" \
            --inventory "${inventory}" \
            --action uninstall-catalog \
            --args "--recursive --inputDir ${inputcasedir} ${dryRun:+--dryRun }" \
            --tolerance "${tolerance_val}"

        if [[ $? -ne 0 ]]; then
            err_exit "Uninstalling dependent catalog source: ${dep_case} failed"
        fi

    done
}

# Check to see if the namespace is already the target of an OperatorGroup. If not, create one.
 # Need to have a single OG, otherwise OLM doesn't like.
install_operator_group() {
    echo "check for any existing operator group in ${namespace} ..."

    if [[ $($kubernetesCLI get og -n "${namespace}" -o=go-template --template='{{len .items}}') -gt 0 ]]; then
        echo "found operator group"
        $kubernetesCLI get og -n "${namespace}" -o yaml
        return
    fi

    echo "no existing operator group found"

    echo "------------- Installing operator group for $namespace -------------"

    local opgrp_file="${casePath}/inventory/${inventory}/files/op-olm/operator_group.yaml"
    validate_file_exists "${opgrp_file}"

    sed <"${opgrp_file}" "s|REPLACE_NAMESPACE|${namespace}|g" | tee >($kubernetesCLI apply ${dryRun} -n "${namespace}" -f -) | cat

    echo "done"
}

# install_catalog is ONLY used for offline(airgapped) standalone APIC install
install_catalog() {
    validate_install_catalog

    # install all catalogs of subcases first
    if [[ ${recursive_action} -eq 1 ]]; then
        install_dependent_catalogs
    fi

    echo "-------------Installing catalog source-------------"

    local catsrc_file="${casePath}/inventory/${inventory}/files/op-olm/cv_catalog_source.yaml"

    # Verfy expected yaml files for install exit
    validate_file_exists "${catsrc_file}"

    # Apply yaml files manipulate variable input as required
    if [[ -z $registry ]]; then
        # If an additional arg named registry is NOT passed in, then just apply     
        tee >($kubernetesCLI apply ${dryRun} -f -) < "${catsrc_file}"
    else
        # If an additional arg named registry is passed in, then adjust the name of the image and apply 
        local catsrc_image_orig=$(grep "image:" "${catsrc_file}" | awk '{print$2}')
  
        # replace original registry with local registry
        local catsrc_image_mod="${registry}/$(echo "${catsrc_image_orig}" | sed -e "s/[^/]*\///")"

        # apply catalog source
        sed "${catsrc_file}" -e "s|${catsrc_image_orig}|${catsrc_image_mod}|g" | tee >($kubernetesCLI apply ${dryRun} -f -) | cat
    fi

    echo "done"
}


uninstall_catalog() {
    validate_install_catalog "uninstall"

    # uninstall all catalogs of subcases first
    if [[ ${recursive_action} -eq 1 ]]; then
        uninstall_dependent_catalogs
    fi

    local catsrc_file="${casePath}"/inventory/"${inventory}"/files/op-olm/cv_catalog_source.yaml

    echo "-------------Uninstalling catalog source-------------"
    $kubernetesCLI delete -f "${catsrc_file}" --ignore-not-found=true ${dryRun}
}

install_operator() {
# Verfiy arguments are valid
    validate_install_args

    # install all operators of subcases first
    if [[ ${recursive_action} -eq 1 ]]; then
        install_dependent_operators
    fi

    install_operator_group

    # Proceed with install
    echo "-------------Installing via OLM-------------"
    [[ ! -f "${casePath}"/inventory/"${inventory}"/files/op-olm/subscription.yaml ]] && { err_exit "Missing required subscription yaml, exiting deployment."; }

    # check if catalog source is installed
    if ! $kubernetesCLI get catsrc "${caseCatalogName}" -n "${catalogNamespace}"; then
        err_exit "expected catalog source '${caseCatalogName}' expected to be installed namespace '${catalogNamespace}'"
    fi

    # - subscription
   # sed <"${casePath}"/inventory/"${inventory}"/files/op-olm/subscription.yaml "s|REPLACE_NAMESPACE|${namespace}|g" | sed "s|REPLACE_CHANNEL_NAME|$channelName|g" | $kubernetesCLI apply -n "${namespace}" -f -
    sed <"${casePath}"/inventory/"${inventory}"/files/op-olm/subscription.yaml "s|REPLACE_NAMESPACE|${namespace}|g" | $kubernetesCLI apply -n "${namespace}" -f -
}

# Installs the operators (native) of any dependencies
install_dependent_operators() {

    local dep_case=""

    for dep in $case_depedencies; do
        local dep_case="$(dependent_case_tgz "${dep}" "${inputcasedir}")"

        echo "-------------Installing dependent operator: ${dep_case} -------------"

        validate_file_exists "${dep_case}"
        local inventory=""
        inventory=$(dependent_inventory_item "${dep}")

        cloudctl case launch \
            --case "${dep_case}" \
            --namespace "${namespace}" \
            --inventory "${inventory}" \
            --action install-operator-native \
            --args "--registry ${registry} --inputDir ${inputcasedir} --recursive ${dryRun:+--dryRun }" \
            --tolerance "${tolerance_val}"

        if [[ $? -ne 0 ]]; then
            err_exit "installing dependent catalog for '${dep_case}' failed"
        fi
    done
}

uninstall_operator() {
    echo "-------------Uninstalling operator-------------"
    $kubernetesCLI delete -n ${namespace} subs ibm-cp4a-operator-catalog-subscription --ignore-not-found=true
    $kubernetesCLI delete -n ${namespace} og ibm-cp4a-operator-catalog-group --ignore-not-found=true
    $kubernetesCLI delete CatalogSource ibm-cp4a-operator-catalog -n "${catalogNamespace}" --ignore-not-found=true

    # TODO -- could do a better job cleaning up!
}

uninstall_dependent_operators() {

    local dep_case=""

    for dep in $case_depedencies; do
        local dep_case="$(dependent_case_tgz "${dep}" "${inputcasedir}")"
        echo "-------------Uninstalling dependent operator: ${dep_case}-------------"

        validate_file_exists "${dep_case}"
        local inventory=""
        inventory=$(dependent_inventory_item "${dep}")

        cloudctl case launch \
            --case "${dep_case}" \
            --namespace "${namespace}" \
            --inventory "${inventory}" \
            --action uninstall-operator-native \
            --args "--recursive --inputDir ${inputcasedir} ${dryRun:+--dryRun }" \
            --tolerance "${tolerance_val}"

        if [[ $? -ne 0 ]]; then
            err_exit "Uninstalling dependent catalog source: ${dep_case} failed"
        fi

    done
}

retag_dependent_catalog_images() {
    echo "-------------retag_dependent_catalog_images noop-------------"
}

retag_catalog_image() {
    echo "-------------retag_catalog_image noop-------------"
}

install_operator_native() {
    echo "Not supported"
    exit 1
}
uninstall_operator_native() {
    echo "Not supported"
    exit 1
}
delete_custom_resources() {
    echo "Not supported"
    exit 1
}
apply_custom_resources() {
    echo "Not supported"
    exit 1
}

configure_cluster_pull_secret() {
    echo "-------------Configuring cluster pullsecret-------------"
    REGISTRY_SECRETS=$(${scriptDir}/airgap.sh registry secret -l)
    # configure global pull secret if an authentication secret exists on disk
    for i in $REGISTRY_SECRETS; do
        if [[ "${registry}" =~ "${i}" ]]; then
            "${scriptDir}"/airgap.sh cluster update-pull-secret --registry "${i}" "${dryRun}"
        else
            echo "Skipping configuring cluster pullsecret: No authentication exists for ${registry}"
        fi
    done
}

