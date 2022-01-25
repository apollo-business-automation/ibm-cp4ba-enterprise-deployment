#!/bin/bash
# set -x
###############################################################################
#
# Licensed Materials - Property of IBM
#
# (C) Copyright IBM Corp. 2020. All Rights Reserved.
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
###############################################################################
CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

# Import common utilities and environment variables
source ${CUR_DIR}/helper/common.sh

# USE_STAGE="false"
# deployFNCM="true"
# deployODM="true"
# deployADS="true"
# deployBAA="true"
# deployBAW="true"
# deployADP="true"
# INFRA_NAME_ONECLICK="testnode"
# STORAGE_CLASS="sc1"

DOCKER_RES_SECRET_NAME="admin.registrykey"
DOCKER_REG_USER=""
SCRIPT_MODE=$1

if [[ "$SCRIPT_MODE" == "dev" || "$SCRIPT_MODE" == "review" || "$USE_STAGE" == "true" ]] # During dev, OLM uses stage image repo
then
    DOCKER_REG_SERVER="cp.stg.icr.io"
else
    DOCKER_REG_SERVER="cp.icr.io"
fi
# read -rsn1 -p"Press any key to continue DOCKER_REG_SERVER:$DOCKER_REG_SERVER";echo
DOCKER_REG_KEY=""
REGISTRY_IN_FILE="cp.icr.io"
OPERATOR_IMAGE=${DOCKER_REG_SERVER}/cp/cp4a/icp4a-operator:20.0.3

old_db2="docker.io\/ibmcom"
old_db2_alpine="docker.io\/alpine"
old_ldap="docker.io\/osixia"
old_db2_etcd="quay.io\/coreos"
old_busybox="docker.io\/library"

TEMP_FOLDER=${CUR_DIR}/.tmp
BAK_FOLDER=${CUR_DIR}/.bak
FINAL_CR_FOLDER=${CUR_DIR}/generated-cr

DEPLOY_TYPE_IN_FILE_NAME="" # Default value is empty
OPERATOR_FILE=${PARENT_DIR}/install/cert-kubernetes/descriptors/operator.yaml
OPERATOR_FILE_TMP=$TEMP_FOLDER/.operator_tmp.yaml
OPERATOR_FILE_BAK=$BAK_FOLDER/.operator.yaml

OPERATOR_PVC_FILE=${PARENT_DIR}/install/cert-kubernetes/descriptors/operator-shared-pvc.yaml
OPERATOR_PVC_FILE_TMP1=$TEMP_FOLDER/.operator-shared-pvc_tmp1.yaml
OPERATOR_PVC_FILE_TMP=$TEMP_FOLDER/.operator-shared-pvc_tmp.yaml
OPERATOR_PVC_FILE_BAK=$BAK_FOLDER/.operator-shared-pvc.yaml


CP4A_PATTERN_FILE_TMP=$TEMP_FOLDER/.ibm_cp4a_cr_final_tmp.yaml
CP4A_PATTERN_FILE_BAK=$FINAL_CR_FOLDER/ibm_cp4a_cr_final.yaml
CP4A_EXISTING_BAK=$TEMP_FOLDER/.ibm_cp4a_cr_final_existing_bak.yaml
CP4A_EXISTING_TMP=$TEMP_FOLDER/.ibm_cp4a_cr_final_existing_tmp.yaml

JDBC_DRIVER_DIR=${CUR_DIR}/jdbc
SAP_LIB_DIR=${CUR_DIR}/saplibs
ACA_MODEL_FILES_DIR=../ACA/configuration-ha/
PLATFORM_SELECTED=""
PATTERN_SELECTED=""
COMPONENTS_SELECTED=""
OPT_COMPONENTS_CR_SELECTED=""
OPT_COMPONENTS_SELECTED=()
LDAP_TYPE=""

FOUNDATION_CR_SELECTED=""
optional_component_arr=()
optional_component_cr_arr=()
foundation_component_arr=()
FOUNDATION_FULL_ARR=("BAN" "RR" "BAS" "UMS" "AE")
OPTIONAL_COMPONENT_FULL_ARR=("bai" "css" "cmis" "es" "ier" "iccsap" "tm" "ums" "ads_designer" "ads_runtime" "app_designer" "decisionCenter" "decisionServerRuntime" "decisionRunner" "ae_data_persistence" "baw_authoring" "auto_service" "document_processing_runtime" "document_processing_designer")

function validate_kube_oc_cli(){
    if  [[ $PLATFORM_SELECTED == "OCP" || $PLATFORM_SELECTED == "ROKS" ]]; then
        which oc &>/dev/null
        [[ $? -ne 0 ]] && \
        echo -e  "\x1B[1;31mUnable to locate an OpenShift CLI. You must install it to run this script.\x1B[0m" && \
        exit 1
    fi
    if  [[ $PLATFORM_SELECTED == "other" ]]; then
        which kubectl &>/dev/null
        [[ $? -ne 0 ]] && \
        echo -e  "\x1B[1;31mUnable to locate Kubernetes CLI, You must install it to run this script.\x1B[0m" && \
        exit 1
    fi
}

function validate_docker_podman_cli(){
    if [[ $OCP_VERSION == "3.11" || "$machine" == "Mac" ]];then
        which docker &>/dev/null
        [[ $? -ne 0 ]] && \
            echo -e  "\x1B[1;31mUnable to locate docker, please install it first.\x1B[0m" && \
            exit 1
    elif [[ $OCP_VERSION == "4.4OrLater" ]]
    then
        which podman &>/dev/null
        [[ $? -ne 0 ]] && \
            echo -e "\x1B[1;31mUnable to locate podman, please install it first.\x1B[0m" && \
            exit 1
    fi
}

function containsElement(){
    local e match="$1"
    shift
    for e; do [[ "$e" == "$match" ]] && return 0; done
    return 1
}

function containsObjectStore(){
    OBJECT_NAME=$1
    FILE=$2
    os_num=0
    os_index_array=()
    while true; do
        object_name_tmp=`cat $FILE | ${YQ_CMD} r - spec.datasource_configuration.dc_os_datasources.[$os_num].dc_common_os_datasource_name`
        if [ -z "$object_name_tmp" ]; then
            break
        else
            if [[ "$OBJECT_NAME" == "$object_name_tmp" ]]; then
                os_index_array=( "${os_index_array[@]}" "${os_num}" )
            fi
        fi
        ((os_num++))
    done
}

function containsInitObjectStore(){
    OBJECT_NAME=$1
    FILE=$2
    os_num=0
    os_index_array=()
    while true; do
        object_name_tmp=`cat $FILE | ${YQ_CMD} r - spec.initialize_configuration.ic_obj_store_creation.object_stores.[$os_num].oc_cpe_obj_store_display_name`
        if [ -z "$object_name_tmp" ]; then
            break
        else
            if [[ "$OBJECT_NAME" == "$object_name_tmp" ]]; then
                os_index_array=( "${os_index_array[@]}" "${os_num}" )
            fi
        fi
        ((os_num++))
    done
}

function containsInitLDAPGroups(){
    FILE=$1
    ldap_num=0
    ldap_groups_index_array=()
    while true; do
        name_tmp=`cat $FILE | ${YQ_CMD} r - spec.initialize_configuration.ic_ldap_creation.ic_ldap_admins_groups_name.[$ldap_num]`
        if [ -z "$name_tmp" ]; then
            break
        else
            ldap_groups_index_array=( "${ldap_groups_index_array[@]}" "${ldap_num}" )
        fi
        ((ldap_num++))
    done
}

function containsInitLDAPUsers(){
    FILE=$1
    ldap_num=0
    ldap_users_index_array=()
    while true; do
        name_tmp=`cat $FILE | ${YQ_CMD} r - spec.initialize_configuration.ic_ldap_creation.ic_ldap_admin_user_name.[$ldap_num]`
        if [ -z "$name_tmp" ]; then
            break
        else
            ldap_users_index_array=( "${ldap_users_index_array[@]}" "${ldap_num}" )
        fi
        ((ldap_num++))
    done
}

function containsBAWInstance(){
    BAW_INS_NAME=$1
    FILE=$2
    baw_instance_num=0
    baw_index_array=()
    while true; do
        name_tmp=`cat $FILE | ${YQ_CMD} r - spec.baw_configuration.[$baw_instance_num].name`
        if [ -z "$name_tmp" ]; then
            break
        else
            if [[ "$BAW_INS_NAME" == "$name_tmp" ]]; then
                baw_index_array=( "${baw_index_array[@]}" "${baw_instance_num}" )
            fi
        fi
        ((baw_instance_num++))
    done
}

function containsAEInstance(){
    FILE=$1
    ae_instance_num=0
    ae_index_array=()
    while true; do
        name_tmp=`cat $FILE | ${YQ_CMD} r - spec.application_engine_configuration.[$ae_instance_num].name`
        if [ -z "$name_tmp" ]; then
            break
        else
            ae_index_array=( "${ae_index_array[@]}" "${ae_instance_num}" )
        fi
        ((ae_instance_num++))
    done
}

function select_platform(){
    PLATFORM_SELECTED="ROKS"
    
    if [[ "$PLATFORM_SELECTED" == "OCP" || "$PLATFORM_SELECTED" == "ROKS" ]]; then
        CLI_CMD=oc
    elif [[ "$PLATFORM_SELECTED" == "other" ]]
    then
        CLI_CMD=kubectl
    fi

    validate_kube_oc_cli
}

function check_ocp_version(){
    OCP_VERSION="4.4OrLater"
}

function select_pattern(){
# This function support mutiple checkbox, if do not select anything, it will return None

    PATTERNS_SELECTED=""
    choices_pattern=()
    pattern_arr=()
    pattern_cr_arr=()
    AUTOMATION_SERVICE_ENABLE=""
    AE_DATA_PERSISTENCE_ENABLE=""
    CPE_FULL_STORAGE=""

    if [[ "${DEPLOYMENT_TYPE}" == "demo" ]];
    then
        options=("FileNet Content Manager" "Operational Decision Manager" "Automation Decision Services" "Business Automation Application" "Business Automation Workflow and Automation Workstream Services" "IBM Automation Document Processing")
        options_cr_val=("content" "decisions" "decisions_ads" "application" "workflow-workstreams" "document_processing")
        foundation_0=("BAN" "RR")                 # Foundation for FileNet Content Manager
        foundation_1=("BAN" "RR")                # Foundation for Operational Decision Manager
        foundation_2=("BAN" "RR" "UMS")     # Foundation for Automation Decision Services
        foundation_3=("BAN" "RR" "UMS" "BAS")     # Foundation for Business Automation Applications (full)
        foundation_4=("BAN" "RR" "UMS" "AE" "BAS")           # Foundation for Business Automation Workflow and workstreams(Demo)
        foundation_5=("BAN" "RR" "AE" "BAS" "UMS")  # Foundation for IBM Automation Document Processing
    else
        options=("FileNet Content Manager" "Operational Decision Manager" "Automation Decision Services" "Business Automation Application" "Business Automation Workflow" "(a) Workflow Authoring" "(b) Workflow Runtime" "Automation Workstream Services" "IBM Automation Document Processing" "(a) Development Environment" "(b) Runtime Environment")
        options_cr_val=("content" "decisions" "decisions_ads" "application" "workflow" "workflow-authoring" "workflow-runtime" "workstreams" "document_processing" "document_processing_designer" "document_processing_runtime")
        foundation_0=("BAN" "RR")                 # Foundation for FileNet Content Manager
        foundation_1=("BAN" "RR")                 # Foundation for Operational Decision Manager
        foundation_2=("BAN" "RR" "UMS")     # Foundation for Automation Decision Services
        foundation_3=("BAN" "RR" "UMS" "AE")     # Foundation for Business Automation Applications (full)
        foundation_4=("BAN" "RR")           # Foundation for dummy
        foundation_5=("BAN" "RR" "UMS" "BAS" "AE")           # Foundation for Business Automation Workflow - Workflow Authoring (5a)
        foundation_6=("BAN" "RR" "UMS" "AE")           # Foundation for Business Automation Workflow - Workflow Runtime (5b)
        foundation_7=("BAN" "RR" "UMS" "AE")           # Foundation for Automation Workstream Services (6)
        foundation_8=("BAN" "RR")  # Foundation for IBM Automation Document Processing
        foundation_9=("BAN" "RR" "AE" "BAS" "UMS")  # Foundation for IBM Automation Document Processing - 7a Development Environment
        foundation_10=("BAN" "RR" "AE" "UMS")  # Foundation for IBM Automation Document Processing - 7b Runtime Environment
        foundation_11=("BAN" "RR" "UMS" "AE")           # Foundation for Business Automation Workflow and workstreams(5b+6)
    fi

    patter_ent_input_array=("1" "2" "3" "4" "5a" "5b" "5A" "5B" "6" "7a" "7b" "7A" "7B" "5b,6" "5B,6" "5b, 6" "5B, 6" "5b 6" "5B 6")
    tips1="\x1B[1;31mTips\x1B[0m:\x1B[1mPress [ENTER] to accept the default (None of the patterns is selected)\x1B[0m"
    tips2="\x1B[1;31mTips\x1B[0m:\x1B[1mPress [ENTER] when you are done\x1B[0m"
    pattern_tips="\x1B[1mInfo: Business Automation Navigator will be automatically installed in the environment as it is part of the Cloud Pak for Automation foundation platform. \n\nTips:  After you make your first selection you will be able to make additional selections since you can combine multiple selections.\n\x1B[0m"
    baw_iaws_tips="\x1B[1mInfo: Note that Business Automation Workflow Authoring (5a) cannot be installed together with Automation Workstream Services (6). However, Business Automation Workflow Runtime (5b) can be installed together with Automation Workstream Services (6).\n\x1B[0m"

    indexof() {
        i=-1
        for ((j=0;j<${#options_cr_val[@]};j++));
        do [ "${options_cr_val[$j]}" = "$1" ] && { i=$j; break; }
        done
        echo $i
    }
    if [[ $deployFNCM == "true" ]];then
        pattern_arr=( "${pattern_arr[@]}" "${options[0]}" ) 
        pattern_cr_arr=( "${pattern_cr_arr[@]}" "${options_cr_val[0]}" )
        foundation_component_arr=( "${foundation_component_arr[@]}" "${foundation_0[@]}" )
    fi
    if [[ $deployODM == "true" ]];then
        pattern_arr=( "${pattern_arr[@]}" "${options[1]}" ) 
        pattern_cr_arr=( "${pattern_cr_arr[@]}" "${options_cr_val[1]}" )
        foundation_component_arr=( "${foundation_component_arr[@]}" "${foundation_1[@]}" )       
    fi
    if [[ $deployADS == "true" ]];then
        pattern_arr=( "${pattern_arr[@]}" "${options[2]}" ) 
        pattern_cr_arr=( "${pattern_cr_arr[@]}" "${options_cr_val[2]}" )
        foundation_component_arr=( "${foundation_component_arr[@]}" "${foundation_2[@]}" )           
    fi
    if [[ $deployBAA == "true" ]];then
        pattern_arr=( "${pattern_arr[@]}" "${options[3]}" ) 
        pattern_cr_arr=( "${pattern_cr_arr[@]}" "${options_cr_val[3]}" )
        foundation_component_arr=( "${foundation_component_arr[@]}" "${foundation_3[@]}" )       
    fi
    if [[ $deployBAW == "true" ]];then
        pattern_arr=( "${pattern_arr[@]}" "${options[4]}" ) 
        pattern_cr_arr=( "${pattern_cr_arr[@]}" "${options_cr_val[4]}" )
        foundation_component_arr=( "${foundation_component_arr[@]}" "${foundation_4[@]}" )            
    fi
    if [[ $deployADP == "true" ]];then
        pattern_arr=( "${pattern_arr[@]}" "${options[5]}" ) 
        pattern_cr_arr=( "${pattern_cr_arr[@]}" "${options_cr_val[5]}" )
        foundation_component_arr=( "${foundation_component_arr[@]}" "${foundation_5[@]}" )  
    fi

    # 4Q: add workflow-workstream into pattern list when select both workflow-runtime and workstream
    if [[ " ${pattern_cr_arr[@]} " =~ "workflow" && " ${pattern_cr_arr[@]} " =~ "workstreams" ]]; then
        pattern_cr_arr=( "${pattern_cr_arr[@]}" "workflow-workstreams" )
        foundation_ww=("BAN" "RR" "UMS" "AE")
        foundation_component_arr=( "${foundation_component_arr[@]}" "${foundation_ww[@]}" )
    fi

    if [ "${#pattern_arr[@]}" -eq "0" ]; then
        PATTERNS_SELECTED="None"
        printf "\x1B[1;31mPlease select one pattern at least, exiting... \n\x1B[0m"
        exit 1
    else
        PATTERNS_SELECTED=$( IFS=$','; echo "${pattern_arr[*]}" )
        PATTERNS_CR_SELECTED=$( IFS=$','; echo "${pattern_cr_arr[*]}" )

    fi
    if [[ "$DEPLOYMENT_TYPE" == "enterprise" ]]; then
        select_ae_data_persistence
        AUTOMATION_SERVICE_ENABLE="No"
    fi
    # select_cpe_full_storage
    CPE_FULL_STORAGE="No"
    FOUNDATION_CR_SELECTED=($(echo "${foundation_component_arr[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

    x=0;while [ ${x} -lt ${#FOUNDATION_CR_SELECTED[*]} ] ; do FOUNDATION_CR_SELECTED_LOWCASE[$x]=$(tr [A-Z] [a-z] <<< ${FOUNDATION_CR_SELECTED[$x]}); let x++; done
    FOUNDATION_DELETE_LIST=($(echo "${FOUNDATION_CR_SELECTED[@]}" "${FOUNDATION_FULL_ARR[@]}" | tr ' ' '\n' | sort | uniq -u))

    PATTERNS_CR_SELECTED=($(echo "${pattern_cr_arr[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

    # echo "length of optional_component_cr_arr:${#optional_component_cr_arr[@]}"
    # echo "!!optional_component_cr_arr!!!${optional_component_cr_arr[*]}"
    # echo "EXISTING_PATTERN_ARR: ${EXISTING_PATTERN_ARR[*]}"
    # echo "PATTERNS_CR_SELECTED: ${PATTERNS_CR_SELECTED[*]}"
    # echo "EXISTING_OPT_COMPONENT_ARR: ${EXISTING_OPT_COMPONENT_ARR[*]}"
    # echo "OPT_COMPONENTS_CR_SELECTED: ${OPT_COMPONENTS_CR_SELECTED[*]}"
    # echo "FOUNDATION_CR_SELECTED_LOWCASE: ${FOUNDATION_CR_SELECTED_LOWCASE[*]}"
    # echo "FOUNDATION_DELETE_LIST: ${FOUNDATION_DELETE_LIST[*]}"
    # echo "OPTIONAL_COMPONENT_DELETE_LIST: ${OPTIONAL_COMPONENT_DELETE_LIST[*]}"
    # echo "KEEP_COMPOMENTS: ${KEEP_COMPOMENTS[*]}"
    # echo "REMOVED FOUNDATION_CR_SELECTED FROM OPTIONAL_COMPONENT_DELETE_LIST: ${OPTIONAL_COMPONENT_DELETE_LIST[*]}"
    # echo "pattern list in CR: ${pattern_joined}"
    # echo "optional components list in CR: ${opt_components_joined}"
    # echo "length of optional_component_arr:${#optional_component_arr[@]}"

    # read -rsn1 -p"Press any key to continue (DEBUG MODEL)";echo

}

function select_optional_component(){
# This function support mutiple checkbox, if do not select anything, it will return
    OPT_COMPONENTS_CR_SELECTED=()
    OPTIONAL_COMPONENT_DELETE_LIST=()
    KEEP_COMPOMENTS=()
    OPT_COMPONENTS_SELECTED=()
    optional_component_arr=()
    optional_component_cr_arr=()
    BAI_SELECTED=""
    show_optional_components(){
        COMPONENTS_SELECTED=""
        choices_component=()
        component_arr=()

        tips1="\x1B[1;31mTips\x1B[0m:\x1B[1m Press [ENTER] to accept the default (None of the components is selected)\x1B[0m"
        tips2="\x1B[1;31mTips\x1B[0m:\x1B[1m Press [ENTER] when you are done\x1B[0m"
        fncm_tips="\x1B[1mNote: IBM Enterprise Records (IER), IBM Content Collector for SAP (ICCSAP) and Task Manager (TM) do not integrate with User Management Service (UMS).\n"
        ads_tips="\x1B[1mTips:\x1B[0m Decision Designer is typically required if you are deploying a development or test environment.\nThis feature will automatically install Business Automation Studio, if not already present. \n\nDecision Runtime is typically recommended if you are deploying a test or production environment. \n\nYou should choose at least one these features to have a minimum environment configuration.\n"
        if [[ $DEPLOYMENT_TYPE == "demo" ]];then
            decision_tips="\x1B[1mTips:\x1B[0m Decision Center, Rule Execution Server and Decision Runner will be installed by default.\n"
        else
            decision_tips="\x1B[1mTips:\x1B[0m Decision Center is typically required for development and testing environments. \nRule Execution Server is typically required for testing and production environments and for using Business Automation Insights. \nYou should choose at least one these 2 features to have a minimum environment configuration. \n"
        fi
        application_tips="\x1B[1mTips:\x1B[0m Application Designer is typically required if you are deploying a development or test environment.\nThis feature will automatically install Business Automation Studio, if not already present. \n\nApplication Engine is automatically installed in the environment.  \n\nMake your selection or press enter to proceed. \n"

        indexof() {
            i=-1
            for ((j=0;j<${#optional_component_cr_arr[@]};j++));
            do [ "${optional_component_cr_arr[$j]}" = "$1" ] && { i=$j; break; }
            done
            echo $i
        }
        menu() {
            clear
            echo -e "\x1B[1;31mPattern \"$item_pattern\": \x1B[0m\x1B[1mSelect optional components: \x1B[0m"
            # echo -e "\x1B[1mSelect optional components: \x1B[0m"
            containsElement "bai" "${EXISTING_OPT_COMPONENT_ARR[@]}"
            bai_cr_retVal=$?
            for i in ${!optional_components_list[@]}; do
                if [[ ("${choices_component[i]}" == "(Selected)" || "${choices_component[i]}" == "(Installed)") && "${optional_components_list[i]}" == "Business Automation Insights" ]];then
                    BAI_SELECTED="Yes"
                elif [[ ( $bai_cr_retVal -ne 0 || "${choices_component[i]}" == "(To Be Uninstalled)") && "${optional_components_list[i]}" == "Business Automation Insights" ]]
                then
                    BAI_SELECTED="No"
                fi
            done

            for i in ${!optional_components_list[@]}; do
                containsElement "${optional_components_cr_list[i]}" "${EXISTING_OPT_COMPONENT_ARR[@]}"
                retVal=$?
                containsElement "${optional_components_cr_list[i]}" "${optional_component_cr_arr[@]}"
                selectedVal=$?
                if [ $retVal -ne 0 ]; then
                    if [[ "${item_pattern}" == "FileNet Content Manager" || ( "${item_pattern}" == "Operational Decision Manager" && "${DEPLOYMENT_TYPE}" == "enterprise" ) ]];then
                        if [[ "${optional_components_list[i]}" == "User Management Service" && "${BAI_SELECTED}" == "Yes" ]];then
                            printf "%1d) %s \x1B[1m%s\x1B[0m\n" $((i+1)) "${optional_components_list[i]}"  "(Selected)"
                        elif [ $selectedVal -ne 0 ]
                        then
                            printf "%1d) %s \x1B[1m%s\x1B[0m\n" $((i+1)) "${optional_components_list[i]}"  "${choices_component[i]}"
                        else
                            printf "%1d) %s \x1B[1m%s\x1B[0m\n" $((i+1)) "${optional_components_list[i]}"  "(Selected)"
                        fi
                    else
                        if [ $selectedVal -ne 0 ]; then
                            printf "%1d) %s \x1B[1m%s\x1B[0m\n" $((i+1)) "${optional_components_list[i]}"  "${choices_component[i]}"
                        else
                            printf "%1d) %s \x1B[1m%s\x1B[0m\n" $((i+1)) "${optional_components_list[i]}"  "(Selected)"
                        fi
                    fi
                else
                    if [[ "${optional_components_list[i]}" == "User Management Service" ]];then
                        if [[ "${choices_component[i]}" == "(To Be Uninstalled)" ]]; then
                            printf "%1d) %s \x1B[1m%s\x1B[0m\n" $((i+1)) "${optional_components_list[i]}"  "${choices_component[i]}"
                        else
                            printf "%1d) %s \x1B[1m%s\x1B[0m\n" $((i+1)) "${optional_components_list[i]}"  "(Installed)"
                        fi
                    elif [[ "${choices_component[i]}" == "(To Be Uninstalled)" ]]
                    then
                        printf "%1d) %s \x1B[1m%s\x1B[0m\n" $((i+1)) "${optional_components_list[i]}"  "${choices_component[i]}"
                    else
                        printf "%1d) %s \x1B[1m%s\x1B[0m\n" $((i+1)) "${optional_components_list[i]}"  "(Installed)"
                        if [[ "${optional_components_cr_list[i]}" == "bai" ]];then
                            BAI_SELECTED="Yes"
                        fi
                    fi
                fi
            done
            if [[ "$msg" ]]; then echo "$msg"; fi
            printf "\n"

            if [[ "${item_pattern}" == "FileNet Content Manager" ]]; then
                echo -e "${fncm_tips}"
            fi
            if [[ "${item_pattern}" == "Automation Decision Services" ]]; then
                echo -e "${ads_tips}"
            fi
            if [[ "${item_pattern}" == "Operational Decision Manager" ]]; then
                echo -e "${decision_tips}"
            fi
            if [[ "${item_pattern}" == "Business Automation Application" ]]; then
                echo -e "${application_tips}"
            fi


            # Show different tips according components select or unselect
            containsElement "(Selected)" "${choices_component[@]}"
            retVal=$?
            if [ $retVal -eq 0 ]; then
                echo -e "${tips2}"
            elif [ $selectedVal -eq 0 ]
            then
                echo -e "${tips2}"
            else
                echo -e "${tips1}"
            fi
# ##########################DEBUG############################
#         for i in "${!choices_component[@]}"; do
#             printf "%s\t%s\n" "$i" "${choices_component[$i]}"
#         done
# ##########################DEBUG############################
        }

        prompt="Enter a valid option [1 to ${#optional_components_list[@]}]: "
        while menu && read -rp "$prompt" num && [[ "$num" ]]; do
            [[ "$num" != *[![:digit:]]* ]] &&
            (( num > 0 && num <= ${#optional_components_list[@]} )) ||
            { msg="Invalid option: $num"; continue; }
            if [[ "${item_pattern}" == "FileNet Content Manager" && "$DEPLOYMENT_TYPE" == "enterprise" ]]; then
                case "$num" in
                "1"|"2"|"3"|"4"|"5"|"6"|"7"|"8")
                    ((num--))
                    ;;
                esac
            elif [[ "${item_pattern}" == "FileNet Content Manager" && "$DEPLOYMENT_TYPE" == "demo" ]]; then
                case "$num" in
                "1"|"2"|"3"|"4"|"5"|"6"|"7")
                    ((num--))
                    ;;
                esac
            else
                ((num--))
            fi
            containsElement "${optional_components_cr_list[num]}" "${EXISTING_OPT_COMPONENT_ARR[@]}"
            retVal=$?
            if [ $retVal -ne 0 ]; then
                [[ "${choices_component[num]}" ]] && choices_component[num]="" || choices_component[num]="(Selected)"
                if [[ "${item_pattern}" == "FileNet Content Manager" || ("${item_pattern}" == "Operational Decision Manager" && "${DEPLOYMENT_TYPE}" == "enterprise") ]]; then
                    if [[ "${optional_components_cr_list[num]}" == "bai" && ${choices_component[num]} == "(Selected)" ]]; then
                        choices_component[num-1]="(Selected)"
                    fi
                    if [[ "${optional_components_cr_list[num]}" == "ums" && ${choices_component[num+1]} == "(Selected)" ]]; then
                        choices_component[num]="(Selected)"
                    fi
                fi
            else
                containsElement "ums" "${EXISTING_OPT_COMPONENT_ARR[@]}"
                ums_retVal=$?
                containsElement "bai" "${EXISTING_OPT_COMPONENT_ARR[@]}"
                bai_retVal=$?
                if [[ "${optional_components_cr_list[num]}" == "bai" && $ums_retVal -eq 0 ]];then
                    ((ums_check_num=num-1))
                    if [[ "${choices_component[num]}" == "(To Be Uninstalled)" ]];then
                        [[ "${choices_component[num]}" ]] && choices_component[num]="" || choices_component[num]=""
                        [[ "${choices_component[num]}" ]] && choices_component[num]="" || choices_component[ums_check_num]=""
                    else
                        [[ "${choices_component[num]}" ]] && choices_component[num]="" || choices_component[num]="(To Be Uninstalled)"
                    fi
                elif [[ "${optional_components_cr_list[num]}" == "ums" && $bai_retVal -eq 0 && ("${choices_component[num+1]}" == "" || "${choices_component[num+1]}" == "(Installed)") ]]
                then
                    [[ "${choices_component[num]}" ]] && choices_component[num]="" || choices_component[num]=""
                else
                    [[ "${choices_component[num]}" ]] && choices_component[num]="" || choices_component[num]="(To Be Uninstalled)"
                fi
            fi
        done

        # printf "\x1B[1mCOMPONENTS selected: \x1B[0m"; msg=" None"
        for i in ${!optional_components_list[@]}; do
            # [[ "${choices_component[i]}" ]] && { printf " \"%s\"" "${optional_components_list[i]}"; msg=""; }

            containsElement "${optional_components_cr_list[i]}" "${EXISTING_OPT_COMPONENT_ARR[@]}"
            retVal=$?
            if [ $retVal -ne 0 ]; then
                # [[ "${choices_component[i]}" ]] && { pattern_arr=( "${pattern_arr[@]}" "${options[i]}" ); pattern_cr_arr=( "${pattern_cr_arr[@]}" "${options_cr_val[i]}" ); msg=""; }
                if [[ "${optional_components_list[i]}" == "External Share" ]]; then
                    [[ "${choices_component[i]}" ]] && { optional_component_arr=( "${optional_component_arr[@]}" "ExternalShare" ); msg=""; }
                elif [[ "${optional_components_list[i]}" == "Task Manager" ]]
                then
                    [[ "${choices_component[i]}" ]] && { optional_component_arr=( "${optional_component_arr[@]}" "TaskManager" ); msg=""; }
                elif [[ "${optional_components_list[i]}" == "Content Search Services" ]]
                then
                    [[ "${choices_component[i]}" ]] && { optional_component_arr=( "${optional_component_arr[@]}" "ContentSearchServices" ); msg=""; }
                elif [[ "${optional_components_list[i]}" == "Decision Center" ]]
                then
                    [[ "${choices_component[i]}" ]] && { optional_component_arr=( "${optional_component_arr[@]}" "DecisionCenter" ); msg=""; }
                elif [[ "${optional_components_list[i]}" == "Rule Execution Server" ]]
                then
                    [[ "${choices_component[i]}" ]] && { optional_component_arr=( "${optional_component_arr[@]}" "RuleExecutionServer" ); msg=""; }
                elif [[ "${optional_components_list[i]}" == "Decision Runner" ]]
                then
                    [[ "${choices_component[i]}" ]] && { optional_component_arr=( "${optional_component_arr[@]}" "DecisionRunner" ); msg=""; }
                elif [[ "${optional_components_list[i]}" == "Decision Designer" ]]
                then
                    [[ "${choices_component[i]}" ]] && { optional_component_arr=( "${optional_component_arr[@]}" "DecisionDesigner" ); msg=""; }
                elif [[ "${optional_components_list[i]}" == "Decision Runtime" ]]
                then
                    [[ "${choices_component[i]}" ]] && { optional_component_arr=( "${optional_component_arr[@]}" "DecisionRuntime" ); msg=""; }
                elif [[ "${optional_components_list[i]}" == "Content Management Interoperability Services" ]]
                then
                    [[ "${choices_component[i]}" ]] && { optional_component_arr=( "${optional_component_arr[@]}" "ContentManagementInteroperabilityServices" ); msg=""; }
                elif [[ "${optional_components_list[i]}" == "User Management Service" ]]
                then
                    [[ "${choices_component[i]}" ]] && { optional_component_arr=( "${optional_component_arr[@]}" "UserManagementService" ); msg=""; }
                elif [[ "${optional_components_list[i]}" == "Business Automation Insights" ]]
                then
                    [[ "${choices_component[i]}" ]] && { optional_component_arr=( "${optional_component_arr[@]}" "BusinessAutomationInsights" ); msg=""; }
                elif [[ "${optional_components_list[i]}" == "Application Designer" ]]
                then
                    [[ "${choices_component[i]}" ]] && { optional_component_arr=( "${optional_component_arr[@]}" "ApplicationDesigner" ); msg=""; }
                elif [[ "${optional_components_list[i]}" == "Business Automation Application Data Persistence" ]]
                then
                    [[ "${choices_component[i]}" ]] && { optional_component_arr=( "${optional_component_arr[@]}" "BusinessAutomationApplicationDataPersistence" ); msg=""; }
                elif [[ "${optional_components_list[i]}" == "IBM Enterprise Records" ]]
                then
                    [[ "${choices_component[i]}" ]] && { optional_component_arr=( "${optional_component_arr[@]}" "IBMEnterpriseRecords" ); msg=""; }
                elif [[ "${optional_components_list[i]}" == "IBM Content Collector for SAP" ]]
                then
                    [[ "${choices_component[i]}" ]] && { optional_component_arr=( "${optional_component_arr[@]}" "IBMContentCollectorforSAP" ); msg=""; }
                else
                    [[ "${choices_component[i]}" ]] && { optional_component_arr=( "${optional_component_arr[@]}" "${optional_components_list[i]}" ); msg=""; }
                fi
                [[ "${choices_component[i]}" ]] && { optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "${optional_components_cr_list[i]}" ); msg=""; }
            else
                if [[ "${choices_component[i]}" == "(To Be Uninstalled)" ]]; then
                    pos=`indexof "${optional_component_cr_arr[i]}"`
                    if [[ "$pos" != "-1" ]]; then
                    { optional_component_cr_arr=(${optional_component_cr_arr[@]:0:$pos} ${optional_component_cr_arr[@]:$(($pos + 1))}); optional_component_arr=(${optional_component_arr[@]:0:$pos} ${optional_component_arr[@]:$(($pos + 1))}); }
                    fi
                else
                    if [[ "${optional_components_list[i]}" == "External Share" ]]; then
                        optional_component_arr=( "${optional_component_arr[@]}" "ExternalShare" )
                    elif [[ "${optional_components_list[i]}" == "Task Manager" ]]
                    then
                        optional_component_arr=( "${optional_component_arr[@]}" "TaskManager" )
                    elif [[ "${optional_components_list[i]}" == "Content Search Services" ]]
                    then
                        optional_component_arr=( "${optional_component_arr[@]}" "ContentSearchServices" )
                    elif [[ "${optional_components_list[i]}" == "Decision Center" ]]
                    then
                        optional_component_arr=( "${optional_component_arr[@]}" "DecisionCenter" )
                    elif [[ "${optional_components_list[i]}" == "Rule Execution Server" ]]
                    then
                        optional_component_arr=( "${optional_component_arr[@]}" "RuleExecutionServer" )
                    elif [[ "${optional_components_list[i]}" == "Decision Runner" ]]
                    then
                        optional_component_arr=( "${optional_component_arr[@]}" "DecisionRunner" )
                    elif [[ "${optional_components_list[i]}" == "Decision Designer" ]]
                    then
                        optional_component_arr=( "${optional_component_arr[@]}" "DecisionDesigner" )
                    elif [[ "${optional_components_list[i]}" == "Decision Runtime" ]]
                    then
                        optional_component_arr=( "${optional_component_arr[@]}" "DecisionRuntime" )
                    elif [[ "${optional_components_list[i]}" == "Content Management Interoperability Services" ]]
                    then
                        optional_component_arr=( "${optional_component_arr[@]}" "ContentManagementInteroperabilityServices" )
                    elif [[ "${optional_components_list[i]}" == "User Management Service" ]]
                    then
                        optional_component_arr=( "${optional_component_arr[@]}" "UserManagementService" )
                    elif [[ "${optional_components_list[i]}" == "Business Automation Insights" ]]
                    then
                        optional_component_arr=( "${optional_component_arr[@]}" "BusinessAutomationInsights" )
                    elif [[ "${optional_components_list[i]}" == "Application Designer" ]]
                    then
                        optional_component_arr=( "${optional_component_arr[@]}" "ApplicationDesigner" )
                    elif [[ "${optional_components_list[i]}" == "Business Automation Application Data Persistence" ]]
                    then
                        optional_component_arr=( "${optional_component_arr[@]}" "BusinessAutomationApplicationDataPersistence" )
                    elif [[ "${optional_components_list[i]}" == "IBM Enterprise Records" ]]
                    then
                        optional_component_arr=( "${optional_component_arr[@]}" "IBMEnterpriseRecords" )
                    elif [[ "${optional_components_list[i]}" == "IBM Content Collector for SAP" ]]
                    then
                        optional_component_arr=( "${optional_component_arr[@]}" "IBMContentCollectorforSAP" )
                    else
                        optional_component_arr=( "${optional_component_arr[@]}" "${optional_components_list[i]}" )
                    fi
                    optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "${optional_components_cr_list[i]}" )
                fi
            fi
        done
        # echo -e "$msg"

        if [ "${#optional_component_arr[@]}" -eq "0" ]; then
            COMPONENTS_SELECTED="None"
        else
            OPT_COMPONENTS_CR_SELECTED=$( IFS=$','; echo "${optional_component_arr[*]}" )

        fi
    }
    for item_pattern in "${pattern_arr[@]}"; do
        while true; do
            case $item_pattern in
                "FileNet Content Manager")
                    # echo "select $item_pattern pattern optional components"
                    if [[ $DEPLOYMENT_TYPE == "demo" ]];then
                        optional_components_list=("Content Search Services" "Content Management Interoperability Services" "IBM Enterprise Records" "IBM Content Collector for SAP" "User Management Service" "Business Automation Insights" "Task Manager")
                        optional_components_cr_list=("css" "cmis" "ier" "iccsap" "ums" "bai" "tm")
                    elif [[ $DEPLOYMENT_TYPE == "enterprise" ]]
                    then
                        optional_components_list=("Content Search Services" "Content Management Interoperability Services" "External Share" "IBM Enterprise Records" "IBM Content Collector for SAP" "User Management Service" "Business Automation Insights" "Task Manager")
                        optional_components_cr_list=("css" "cmis" "es" "ier" "iccsap" "ums" "bai" "tm")
                    fi
                    # show_optional_components
                    containsElement "bai" "${optional_component_cr_arr[@]}"
                    retVal=$?
                    if [[ $retVal -eq 0 ]]; then
                        optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "ums" )
                        optional_component_arr=( "${optional_component_arr[@]}" "UserManagementService" )
                    fi
                    optional_components_list=()
                    optional_components_cr_list=()
                    break
                    ;;
                "Automation Content Analyzer")
                    # echo "Without optional components for $item_pattern pattern."
                    optional_components_list=()
                    optional_components_cr_list=()
                    break
                    ;;
                "Operational Decision Manager")
                    # echo "select $item_pattern pattern optional components"
                    if [[ "${DEPLOYMENT_TYPE}" == "demo" ]]; then
                        optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "decisionCenter" )
                        optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "decisionServerRuntime" )
                        optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "decisionRunner" )
                        optional_components_list=("Business Automation Insights")
                        optional_components_cr_list=("bai")
                    else
                        optional_components_list=("Decision Center" "Rule Execution Server" "Decision Runner" "User Management Service" "Business Automation Insights")
                        optional_components_cr_list=("decisionCenter" "decisionServerRuntime" "decisionRunner" "ums" "bai")
                    fi
                        # show_optional_components
                        containsElement "bai" "${optional_component_cr_arr[@]}"
                        retVal=$?
                        if [[ $retVal -eq 0 ]]; then
                            optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "ums" )
                            optional_component_arr=( "${optional_component_arr[@]}" "UserManagementService" )
                        fi
                        optional_components_list=()
                        optional_components_cr_list=()
                    break
                    ;;
                "Automation Decision Services")
                    # echo "select $item_pattern pattern optional components"
                    if [[ "${DEPLOYMENT_TYPE}" == "demo" ]]; then
                        optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "ads_designer" )
                        optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "ads_runtime" )
                        optional_components_list=("Business Automation Insights")
                        optional_components_cr_list=("bai")
                        # show_optional_components
                        optional_components_list=()
                        optional_components_cr_list=()
                    else
                        optional_components_list=("Business Automation Insights" "Decision Designer" "Decision Runtime")
                        optional_components_cr_list=("bai" "ads_designer" "ads_runtime")
                        # show_optional_components
                        optional_components_list=()
                        optional_components_cr_list=()
                    fi
                    break
                    ;;
                "Business Automation Workflow")
                    # The logic for BAW only in 4Q
                    if [[ $DEPLOYMENT_TYPE == "demo" && $retVal_baw -eq 0 ]]; then
                        optional_components_list=("Business Automation Insights")
                        optional_components_cr_list=("bai")
                        # show_optional_components
                    fi
                    if [[ $DEPLOYMENT_TYPE == "enterprise" && $retVal_baw -eq 0 ]]; then
                        optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "bai" )
                        optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "ae_data_persistence" )
                    fi
                    optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "cmis" )
                    optional_components_list=()
                    optional_components_cr_list=()
                    break
                    ;;
                "(a) Workflow Authoring")
                    if [[ $DEPLOYMENT_TYPE == "enterprise" ]]; then
                        optional_components_list=("Business Automation Insights")
                        optional_components_cr_list=("bai")
                        show_optional_components
                    fi
                    optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "cmis" )
                    optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "baw_authoring" )
                    optional_components_list=()
                    optional_components_cr_list=()
                    break
                    ;;
                "(b) Workflow Runtime")
                    optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "cmis" )
                    optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "bai" )
                    optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "ae_data_persistence" )
                    optional_components_list=()
                    optional_components_cr_list=()
                    break
                    ;;
                "Business Automation Workflow and Automation Workstream Services")
                    if [[ $DEPLOYMENT_TYPE == "demo" ]]; then
                        optional_components_list=("Business Automation Insights")
                        optional_components_cr_list=("bai")
                        # show_optional_components
                    # elif [[ $DEPLOYMENT_TYPE == "enterprise" ]]; then
                    #     optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "bai" )
                    #     optional_component_arr=( "${optional_component_arr[@]}" "BusinessAutomationInsights" )
                    fi
                    optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "cmis" )
                    optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "baw_authoring" )
                    optional_components_list=()
                    optional_components_cr_list=()
                    break
                    ;;
                "Automation Workstream Services")
                    # echo "Without optional components for $item_pattern pattern."
                    optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "cmis" )
                    optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "ae_data_persistence" )
                    optional_components_list=()
                    optional_components_cr_list=()
                    break
                    ;;
                "Business Automation Application")
                    if [[ $DEPLOYMENT_TYPE == "enterprise" ]]; then
                        # echo "select $item_pattern pattern optional components"
                        optional_components_list=("Application Designer")
                        optional_components_cr_list=("app_designer")
                        # show_optional_components
                        optional_components_list=()
                        optional_components_cr_list=()
                    else
                        optional_components_list=()
                        optional_components_cr_list=()
                    fi
                    break
                    ;;
                "Automation Digital Worker")
                    optional_components_list=("Business Automation Insights")
                    optional_components_cr_list=("bai")
                    # show_optional_components
                    optional_components_list=()
                    optional_components_cr_list=()
                    break
                    ;;
                "IBM Automation Document Processing")
                    if [[ $DEPLOYMENT_TYPE == "demo" ]]; then
                        optional_components_list=("Content Search Services" "External Share" "Content Management Interoperability Services")
                        optional_components_cr_list=("css" "es" "cmis")
                        # show_optional_components
                        optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "document_processing_designer" )
                    fi
                    optional_components_list=()
                    optional_components_cr_list=()
                    break
                    ;;
                "(a) Development Environment")
                    if [[ $DEPLOYMENT_TYPE == "enterprise" ]]; then
                        if [[ " ${EXISTING_PATTERN_ARR[@]} " =~ "workflow" || " ${EXISTING_PATTERN_ARR[@]} " =~ "workstreams" || " ${pattern_cr_arr[@]} " =~ "workflow" || " ${pattern_cr_arr[@]} " =~ "workstreams" ]]; then
                            optional_components_list=("Content Search Services" "External Share")
                            optional_components_cr_list=("css" "es")
                        else
                            optional_components_list=("Content Search Services" "External Share" "Content Management Interoperability Services")
                            optional_components_cr_list=("css" "es" "cmis")
                        fi
                        show_optional_components
                        optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "ae_data_persistence" )
                    fi
                    optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "document_processing_designer" )
                    optional_components_list=()
                    optional_components_cr_list=()
                    break
                    ;;
                "(b) Runtime Environment")
                    if [[ $DEPLOYMENT_TYPE == "enterprise" ]]; then
                        if [[ " ${EXISTING_PATTERN_ARR[@]} " =~ "workflow" || " ${EXISTING_PATTERN_ARR[@]} " =~ "workstreams" || " ${pattern_cr_arr[@]} " =~ "workflow" || " ${pattern_cr_arr[@]} " =~ "workstreams" ]]; then
                            optional_components_list=("Content Search Services" "External Share")
                            optional_components_cr_list=("css" "es")
                        else
                            optional_components_list=("Content Search Services" "External Share" "Content Management Interoperability Services")
                            optional_components_cr_list=("css" "es" "cmis")
                        fi
                        show_optional_components
                        optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "ae_data_persistence" )
                    fi
                    optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "document_processing_runtime" )
                    optional_components_list=()
                    optional_components_cr_list=()
                    break
                    ;;
            esac
        done
    done

    if [[ "$AE_DATA_PERSISTENCE_ENABLE" == "Yes" ]]; then
        optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "ae_data_persistence" )
    fi

    if [[ "$AUTOMATION_SERVICE_ENABLE" == "Yes" ]]; then
        optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "auto_service" )
        foundation_component_arr=( "${foundation_component_arr[@]}" "UMS" )
        # optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "ums" ) # remove it when UMS pattern aware auto_service
    fi

    OPT_COMPONENTS_CR_SELECTED=($(echo "${optional_component_cr_arr[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    OPTIONAL_COMPONENT_DELETE_LIST=($(echo "${OPT_COMPONENTS_CR_SELECTED[@]}" "${OPTIONAL_COMPONENT_FULL_ARR[@]}" | tr ' ' '\n' | sort | uniq -u))
    KEEP_COMPOMENTS=($(echo ${FOUNDATION_CR_SELECTED_LOWCASE[@]} ${OPTIONAL_COMPONENT_DELETE_LIST[@]} | tr ' ' '\n' | sort | uniq -d | uniq))
    OPT_COMPONENTS_SELECTED=($(echo "${optional_component_arr[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

    # Will an external LDAP be used as part of the configuration?
    containsElement "es" "${OPT_COMPONENTS_CR_SELECTED[@]}"
    retVal_ext_ldap=$?
    if [[ $retVal_ext_ldap -eq 0 && "${DEPLOYMENT_TYPE}" == "enterprise" ]];then
        set_external_ldap
    fi
}

function select_installation_type(){
    INSTALLATION_TYPE="new"

    if [[ "${INSTALLATION_TYPE}" == "new" ]]; then
        rm -rf $TEMP_FOLDER >/dev/null 2>&1
        rm -rf $BAK_FOLDER >/dev/null 2>&1
        rm -rf $FINAL_CR_FOLDER >/dev/null 2>&1

        mkdir -p $TEMP_FOLDER >/dev/null 2>&1
        mkdir -p $BAK_FOLDER >/dev/null 2>&1
        mkdir -p $FINAL_CR_FOLDER >/dev/null 2>&1
    fi
}

function select_deployment_type(){
    DEPLOYMENT_TYPE="demo"
}

function enable_ae_data_persistence_workflow_authoring(){
    if [[ $DEPLOYMENT_TYPE == "enterprise" ]] ;
    then
        ${COPY_CMD} -rf ${WORKFLOW_AUTHOR_PATTERN_FILE_BAK} ${WORKFLOW_AUTHOR_PATTERN_FILE_TMP}
        content_start="$(grep -n "## object store for AEOS" ${WORKFLOW_AUTHOR_PATTERN_FILE_TMP} | head -n 1 | cut -d: -f1)"
        content_stop="$(tail -n +$content_start < ${WORKFLOW_AUTHOR_PATTERN_FILE_TMP} | grep -n "dc_hadr_max_retries_for_client_reroute: 3" | head -n1 | cut -d: -f1)"
        content_stop=$(( $content_stop + $content_start - 1))
        vi ${WORKFLOW_AUTHOR_PATTERN_FILE_TMP} -c ':'"${content_start}"','"${content_stop}"'s/    # /    ' -c ':wq' >/dev/null 2>&1
        ###########
        content_start="$(grep -n "## Configuration for the application engine object store" ${WORKFLOW_AUTHOR_PATTERN_FILE_TMP} | head -n 1 | cut -d: -f1)"
        content_stop="$(tail -n +$content_start < ${WORKFLOW_AUTHOR_PATTERN_FILE_TMP} | grep -n "dc_os_xa_datasource_name: \"AEOSXA\"" | head -n1 | cut -d: -f1)"
        content_stop=$(( $content_stop + $content_start - 1))
        vi ${WORKFLOW_AUTHOR_PATTERN_FILE_TMP} -c ':'"${content_start}"','"${content_stop}"'s/      # /      ' -c ':wq' >/dev/null 2>&1

        ${COPY_CMD} -rf ${WORKFLOW_AUTHOR_PATTERN_FILE_TMP} ${WORKFLOW_AUTHOR_PATTERN_FILE_BAK}
    fi
}

function enable_ae_data_persistence_baa(){
    if [[ $DEPLOYMENT_TYPE == "enterprise" ]] ;
    then
        ${COPY_CMD} -rf ${APPLICATION_PATTERN_FILE_BAK} ${APPLICATION_PATTERN_FILE_TMP}
        content_start="$(grep -n "The beginning section of database configuration for CP4A" ${APPLICATION_PATTERN_FILE_TMP} | head -n 1 | cut -d: -f1)"
        content_stop="$(tail -n +$content_start < ${APPLICATION_PATTERN_FILE_TMP} | grep -n "dc_os_xa_datasource_name: \"AEOSXA\"" | head -n1 | cut -d: -f1)"
        content_stop=$(( $content_stop + $content_start - 1))
        vi ${APPLICATION_PATTERN_FILE_TMP} -c ':'"${content_start}"','"${content_stop}"'s/  # /  ' -c ':wq' >/dev/null 2>&1
        ${COPY_CMD} -rf ${APPLICATION_PATTERN_FILE_TMP} ${APPLICATION_PATTERN_FILE_BAK}
    fi
}

function select_ldap_type(){
    printf "\n"
    COLUMNS=12
    echo -e "\x1B[1mWhat is the LDAP type used for this deployment? \x1B[0m"
    options=("Microsoft Active Directory" "Tivoli Directory Server / Security Directory Server")
    PS3='Enter a valid option [1 to 2]: '
    select opt in "${options[@]}"
    do
        case $opt in
            "Microsoft Active Directory")
                LDAP_TYPE="AD"
                break
                ;;
            Tivoli*)
                LDAP_TYPE="TDS"
                break
                ;;
            *) echo "invalid option $REPLY";;
        esac
    done

}
function set_ldap_type_foundation(){
    if [[ $DEPLOYMENT_TYPE == "enterprise" ]] ;
    then
        # ${COPY_CMD} -rf ${CP4A_PATTERN_FILE_BAK} ${CP4A_PATTERN_FILE_TMP}

        if [[ "$LDAP_TYPE" == "AD" ]]; then
            content_start="$(grep -n "ad:" ${CP4A_PATTERN_FILE_TMP} | head -n 1 | cut -d: -f1)"
        else
            content_start="$(grep -n "tds:" ${CP4A_PATTERN_FILE_TMP} | head -n 1 | cut -d: -f1)"
        fi
        content_stop="$(tail -n +$content_start < ${CP4A_PATTERN_FILE_TMP} | grep -n "lc_group_filter:" | head -n1 | cut -d: -f1)"
        content_stop=$(( $content_stop + $content_start - 1))
        vi ${CP4A_PATTERN_FILE_TMP} -c ':'"${content_start}"','"${content_stop}"'s/    # /    ' -c ':wq' >/dev/null 2>&1

        # ${COPY_CMD} -rf ${CP4A_PATTERN_FILE_TMP} ${CP4A_PATTERN_FILE_BAK}
    fi
}

function set_ldap_type_content_pattern(){
    if [[ $DEPLOYMENT_TYPE == "enterprise" ]] ;
    then
        ${COPY_CMD} -rf ${CONTENT_PATTERN_FILE_BAK} ${CONTENT_PATTERN_FILE_TMP}

        if [[ "$LDAP_TYPE" == "AD" ]]; then
            content_start="$(grep -n "ad:" ${CONTENT_PATTERN_FILE_TMP} | head -n 1 | cut -d: -f1)"
        else
            content_start="$(grep -n "tds:" ${CONTENT_PATTERN_FILE_TMP} | head -n 1 | cut -d: -f1)"
        fi
        content_stop="$(tail -n +$content_start < ${CONTENT_PATTERN_FILE_TMP} | grep -n "lc_group_filter:" | head -n1 | cut -d: -f1)"
        content_stop=$(( $content_stop + $content_start - 1))
        vi ${CONTENT_PATTERN_FILE_TMP} -c ':'"${content_start}"','"${content_stop}"'s/    # /    ' -c ':wq' >/dev/null 2>&1

        ${COPY_CMD} -rf ${CONTENT_PATTERN_FILE_TMP} ${CONTENT_PATTERN_FILE_BAK}
    fi
}

function set_ldap_type_workstreams_pattern(){
    if [[ $DEPLOYMENT_TYPE == "enterprise" ]] ;
    then
        ${COPY_CMD} -rf ${WORKSTREAMS_PATTERN_FILE_BAK} ${WORKSTREAMS_PATTERN_FILE_TMP}

        if [[ "$LDAP_TYPE" == "AD" ]]; then
            content_start="$(grep -n "ad:" ${WORKSTREAMS_PATTERN_FILE_TMP} | head -n 1 | cut -d: -f1)"
        else
            content_start="$(grep -n "tds:" ${WORKSTREAMS_PATTERN_FILE_TMP} | head -n 1 | cut -d: -f1)"
        fi
        content_stop="$(tail -n +$content_start < ${WORKSTREAMS_PATTERN_FILE_TMP} | grep -n "lc_group_filter:" | head -n1 | cut -d: -f1)"
        content_stop=$(( $content_stop + $content_start - 1))
        vi ${WORKSTREAMS_PATTERN_FILE_TMP} -c ':'"${content_start}"','"${content_stop}"'s/    # /    ' -c ':wq' >/dev/null 2>&1

        ${COPY_CMD} -rf ${WORKSTREAMS_PATTERN_FILE_TMP} ${WORKSTREAMS_PATTERN_FILE_BAK}
    fi
}

function set_ldap_type_workflow_pattern(){
    if [[ $DEPLOYMENT_TYPE == "enterprise" ]] ;
    then
        ${COPY_CMD} -rf ${WORKFLOW_PATTERN_FILE_BAK} ${WORKFLOW_PATTERN_FILE_TMP}

        if [[ "$LDAP_TYPE" == "AD" ]]; then
            content_start="$(grep -n "ad:" ${WORKFLOW_PATTERN_FILE_TMP} | head -n 1 | cut -d: -f1)"
        else
            content_start="$(grep -n "tds:" ${WORKFLOW_PATTERN_FILE_TMP} | head -n 1 | cut -d: -f1)"
        fi
        content_stop="$(tail -n +$content_start < ${WORKFLOW_PATTERN_FILE_TMP} | grep -n "lc_group_filter:" | head -n1 | cut -d: -f1)"
        content_stop=$(( $content_stop + $content_start - 1))
        vi ${WORKFLOW_PATTERN_FILE_TMP} -c ':'"${content_start}"','"${content_stop}"'s/    # /    ' -c ':wq' >/dev/null 2>&1

        ${COPY_CMD} -rf ${WORKFLOW_PATTERN_FILE_TMP} ${WORKFLOW_PATTERN_FILE_BAK}
    fi
}

function set_ldap_type_ww_pattern(){
    if [[ $DEPLOYMENT_TYPE == "enterprise" ]] ;
    then
        ${COPY_CMD} -rf ${WW_PATTERN_FILE_BAK} ${WW_PATTERN_FILE_TMP}

        if [[ "$LDAP_TYPE" == "AD" ]]; then
            content_start="$(grep -n "ad:" ${WW_PATTERN_FILE_TMP} | head -n 1 | cut -d: -f1)"
        else
            content_start="$(grep -n "tds:" ${WW_PATTERN_FILE_TMP} | head -n 1 | cut -d: -f1)"
        fi
        content_stop="$(tail -n +$content_start < ${WW_PATTERN_FILE_TMP} | grep -n "lc_group_filter:" | head -n1 | cut -d: -f1)"
        content_stop=$(( $content_stop + $content_start - 1))
        vi ${WW_PATTERN_FILE_TMP} -c ':'"${content_start}"','"${content_stop}"'s/    # /    ' -c ':wq' >/dev/null 2>&1

        ${COPY_CMD} -rf ${WW_PATTERN_FILE_TMP} ${WW_PATTERN_FILE_BAK}
    fi
}
function set_external_ldap(){
    printf "\n"

    while true; do
        printf "\x1B[1mWill an external LDAP be used as part of the configuration?: \x1B[0m"

        read -rp "" ans
        case "$ans" in
        "y"|"Y"|"yes"|"Yes"|"YES")
            SET_EXT_LDAP="Yes"
            break
            ;;
        "n"|"N"|"no"|"No"|"NO")
            SET_EXT_LDAP="No"
            break
            ;;
        *)
            echo -e "Answer must be \"Yes\" or \"No\"\n"
            ;;
        esac
    done

}
function set_external_share_content_pattern(){
    if [[ $DEPLOYMENT_TYPE == "enterprise" && $SET_EXT_LDAP == "Yes" ]] ;
    then
        containsElement "es" "${OPT_COMPONENTS_CR_SELECTED[@]}"
        retVal=$?
        if [[ $retVal -eq 0 ]]; then
            ${COPY_CMD} -rf ${CONTENT_PATTERN_FILE_BAK} ${CONTENT_PATTERN_FILE_TMP}
            # un-comment ext_ldap_configuration
            content_start="$(grep -n "ext_ldap_configuration:" ${CONTENT_PATTERN_FILE_TMP} | head -n 1 | cut -d: -f1)"
            content_stop="$(tail -n +$content_start < ${CONTENT_PATTERN_FILE_TMP} | grep -n "lc_ldap_group_member_id_map:" | head -n1 | cut -d: -f1)"
            content_stop=$(( $content_stop + $content_start - 1))
            vi ${CONTENT_PATTERN_FILE_TMP} -c ':'"${content_start}"','"${content_stop}"'s/  # /  ' -c ':wq' >/dev/null 2>&1

            # un-comment LDAP
            if [[ "$LDAP_TYPE" == "AD" ]]; then
                content_start="$(grep -n "ad:" ${CONTENT_PATTERN_FILE_TMP} | awk 'NR==2{print $1}' | cut -d: -f1)"
            else
                content_start="$(grep -n "tds:" ${CONTENT_PATTERN_FILE_TMP} | awk 'NR==2{print $1}' | cut -d: -f1)"
            fi
            content_stop="$(tail -n +$content_start < ${CONTENT_PATTERN_FILE_TMP} | grep -n "lc_group_filter:" | head -n1 | cut -d: -f1)"
            content_stop=$(( $content_stop + $content_start - 1))
            vi ${CONTENT_PATTERN_FILE_TMP} -c ':'"${content_start}"','"${content_stop}"'s/    # /    ' -c ':wq'

            ${COPY_CMD} -rf ${CONTENT_PATTERN_FILE_TMP} ${CONTENT_PATTERN_FILE_BAK}
        fi
    fi
}

function set_object_store_content_pattern(){
    if [[ $DEPLOYMENT_TYPE == "enterprise" ]] ;
    then
        ${COPY_CMD} -rf ${CONTENT_PATTERN_FILE_BAK} ${CONTENT_PATTERN_FILE_TMP}
        content_start="$(grep -n "datasource_configuration:" ${CONTENT_PATTERN_FILE_TMP} |  head -n 1 | cut -d: -f1)"
        content_tmp="$(tail -n +$content_start < ${CONTENT_PATTERN_FILE_TMP} | grep -n "dc_os_datasources:" | head -n1 | cut -d: -f1)"
        content_tmp=$(( content_tmp + $content_start - 1))
        content_stop="$(tail -n +$content_tmp < ${CONTENT_PATTERN_FILE_TMP} | grep -n "dc_database_type:" | head -n1 | cut -d: -f1)"
        content_start=$(( $content_stop + $content_tmp - 1))
        content_tmp="$(tail -n +$content_start < ${CONTENT_PATTERN_FILE_TMP} | grep -n "dc_hadr_max_retries_for_client_reroute:" | head -n1 | cut -d: -f1)"
        content_stop=$(( $content_start + $content_tmp - 1))

        for ((j=1;j<${content_os_number};j++))
        do
            vi ${CONTENT_PATTERN_FILE_TMP} -c ':'"${content_start}"','"${content_stop}"' copy '"${content_stop}"'' -c ':wq' >/dev/null 2>&1
        done

        for ((j=1;j<${content_os_number};j++))
        do
            ((obj_num=j+1))
            ${YQ_CMD} w -i ${CONTENT_PATTERN_FILE_TMP} spec.datasource_configuration.dc_os_datasources.[${j}].dc_common_os_datasource_name "FNOS${obj_num}DS"
            ${YQ_CMD} w -i ${CONTENT_PATTERN_FILE_TMP} spec.datasource_configuration.dc_os_datasources.[${j}].dc_common_os_xa_datasource_name "FNOS${obj_num}DSXA"
        done
        ${COPY_CMD} -rf ${CONTENT_PATTERN_FILE_TMP} ${CONTENT_PATTERN_FILE_BAK}
    fi
}

function set_aca_tenant_pattern(){
    if [[ $DEPLOYMENT_TYPE == "enterprise" ]] ;
    then
        ${COPY_CMD} -rf ${ACA_PATTERN_FILE_BAK} ${ACA_PATTERN_FILE_TMP}
        # ${YQ_CMD} d -i ${ACA_PATTERN_FILE_TMP} spec.datasource_configuration.dc_ca_datasource.tenant_databases
        if [ ${#aca_tenant_arr[@]} -eq 0 ]; then
            echo -e "\x1B[1;31mNot any element in ACA tenant list found\x1B[0m:\x1B[1m"
        else
            for i in ${!aca_tenant_arr[@]}; do
               ${YQ_CMD} w -i ${ACA_PATTERN_FILE_TMP} spec.datasource_configuration.dc_ca_datasource.tenant_databases.[${i}] "${aca_tenant_arr[i]}"
             done
        fi
        ${COPY_CMD} -rf ${ACA_PATTERN_FILE_TMP} ${ACA_PATTERN_FILE_BAK}
    fi
}

function select_ae_data_persistence(){
    if [[ " ${EXISTING_OPT_COMPONENT_ARR[@]} " =~ "ae_data_persistence" ]]; then
        foundation_component_arr=( "${foundation_component_arr[@]}" "AE" )
        AE_DATA_PERSISTENCE_ENABLE="Yes"
    else
        if [[ (" ${PATTERNS_CR_SELECTED[@]} " =~ "application" || " ${PATTERNS_CR_SELECTED[@]} " =~ "workflow-authoring") && !(" ${PATTERNS_CR_SELECTED[@]} " =~ "workflow-runtime" || " ${PATTERNS_CR_SELECTED[@]} " =~ "workstreams" || " ${PATTERNS_CR_SELECTED[@]} " =~ "document_processing") ]]; then
            printf "\n"
            while true; do
                printf "\x1B[1mDo you want to enable Business Automation Application Data Persistence? (Yes/No): \x1B[0m"
                read -rp "" ans
                case "$ans" in
                "y"|"Y"|"yes"|"Yes"|"YES")
                    foundation_component_arr=( "${foundation_component_arr[@]}" "AE" )
                    AE_DATA_PERSISTENCE_ENABLE="Yes"
                    # optional_component_cr_arr=( "${optional_component_cr_arr[@]}" "ae_data_persistence" )
                    break
                    ;;
                "n"|"N"|"no"|"No"|"NO"|"")
                    break
                    ;;
                *)
                    echo -e "Answer must be \"Yes\" or \"No\"\n"
                    ;;
                esac
            done
        fi
    fi
}

function input_information(){
    select_installation_type
    if [[ ${INSTALLATION_TYPE} == "existing" ]]; then
        # INSTALL_BAW_IAWS="No"
        prepare_pattern_file
        select_deployment_type
        select_platform
        check_ocp_version
        # validate_docker_podman_cli
    elif [[ ${INSTALLATION_TYPE} == "new" ]]
    then
        select_deployment_type
        select_platform
        check_ocp_version
        # validate_docker_podman_cli
        prepare_pattern_file
        # select_baw_iaws_installation
    fi

    if [[ "${INSTALLATION_TYPE}" == "existing" ]] && (( ${#EXISTING_PATTERN_ARR[@]} == 0 )); then
        echo -e "\x1B[1;31mTHERE IS NOT ANY EXISTING PATTERN FOUND!\x1B[0m"
        read -rsn1 -p"Press any key to continue install new pattern...";echo
    fi

    select_pattern
    select_optional_component
    if [[ "$INSTALLATION_TYPE" == "new" ]]; then
        # get_entitlement_registry
        use_entitlement="yes"
        if [[ "$USE_STAGE" == "true" ]]
        then
            DOCKER_REG_SERVER="cp.stg.icr.io"
        else
            DOCKER_REG_SERVER="cp.icr.io"
        fi
        # if [[ "$use_entitlement" == "no" ]]; then
        #     verify_local_registry_password
        # fi

        if  [[ $PLATFORM_SELECTED == "OCP" || $PLATFORM_SELECTED == "ROKS" ]];
        then
            # get_infra_name
            INFRA_NAME=$INFRA_NAME_ONECLICK
        fi
        # get_storage_class_name
        STORAGE_CLASS_NAME=$STORAGE_CLASS
        SLOW_STORAGE_CLASS_NAME=$STORAGE_CLASS
        MEDIUM_STORAGE_CLASS_NAME=$STORAGE_CLASS
        FAST_STORAGE_CLASS_NAME=$STORAGE_CLASS
        if [[ "$DEPLOYMENT_TYPE" == "enterprise" ]]; then
            select_ldap_type
        fi
    elif [[ "$INSTALLATION_TYPE" == "existing" ]]
    then
        existing_infra_name=`cat $CP4A_EXISTING_BAK | ${YQ_CMD} r - spec.shared_configuration.sc_deployment_hostname_suffix`
        chrlen=${#existing_infra_name}
        INFRA_NAME=${existing_infra_name:21:chrlen}
        existing_ldap_type=`cat $CP4A_EXISTING_BAK | ${YQ_CMD} r - spec.ldap_configuration.lc_selected_ldap_type`
        if [[ "$existing_ldap_type" == "Microsoft Active Directory" ]];then
            LDAP_TYPE="AD"

        elif [[ "$existing_ldap_type" == "IBM Security Directory Server" ]]
        then
            LDAP_TYPE="TDS"
        fi
        existing_docker_reg_server=`cat $CP4A_EXISTING_BAK | ${YQ_CMD} r - spec.shared_configuration.sc_image_repository`
        if [[ "$existing_docker_reg_server" == *"icr.io"* ]]; then
            use_entitlement="yes"
        fi

        local_registry_server=`cat $CP4A_EXISTING_BAK | ${YQ_CMD} r - spec.shared_configuration.sc_image_repository`
        DOCKER_REG_SERVER="${existing_docker_reg_server}"
        # read -rsn1 -p"Press any key to continue existing_docker_reg_server: $existing_docker_reg_server local_registry_server: $local_registry_server";echo
        # convert docker-registry.default.svc:5000/project-name
        # to docker-registry.default.svc:5000\/project-name
        LOCAL_REGISTRY_SERVER=${local_registry_server}
        OIFS=$IFS
        IFS='/' read -r -a docker_reg_url_array <<< "$local_registry_server"
        delim=""
        joined=""
        for item in "${docker_reg_url_array[@]}"; do
                joined="$joined$delim$item"
                delim="\/"
        done
        IFS=$OIFS
        CONVERT_LOCAL_REGISTRY_SERVER=${joined}
        DOCKER_RES_SECRET_NAME=`cat $CP4A_EXISTING_BAK | ${YQ_CMD} r - spec.shared_configuration.image_pull_secrets.[0]`
        STORAGE_CLASS_NAME=`cat $CP4A_EXISTING_BAK | ${YQ_CMD} r - spec.shared_configuration.storage_configuration.sc_dynamic_storage_classname`
        SLOW_STORAGE_CLASS_NAME=`cat $CP4A_EXISTING_BAK | ${YQ_CMD} r - spec.shared_configuration.storage_configuration.sc_slow_file_storage_classname`
        MEDIUM_STORAGE_CLASS_NAME=`cat $CP4A_EXISTING_BAK | ${YQ_CMD} r - spec.shared_configuration.storage_configuration.sc_medium_file_storage_classname`
        FAST_STORAGE_CLASS_NAME=`cat $CP4A_EXISTING_BAK | ${YQ_CMD} r - spec.shared_configuration.storage_configuration.sc_fast_file_storage_classname`
    fi

    containsElement "content" "${PATTERNS_CR_SELECTED[@]}"
    retVal=$?
    if [[ ( $retVal -eq 0 ) && "$DEPLOYMENT_TYPE" == "enterprise" ]]; then
        select_objectstore_number
    fi

    containsElement "document_processing_designer" "${PATTERNS_CR_SELECTED[@]}"
    retVal=$?
    if [[ ( $retVal -eq 0 ) && "$DEPLOYMENT_TYPE" == "enterprise" ]]; then
        select_gpu_document_processing
    fi

    containsElement "document_processing" "${PATTERNS_CR_SELECTED[@]}"
    retVal=$?
    if [[ ( $retVal -eq 0 ) && "$DEPLOYMENT_TYPE" == "demo" ]]; then
        # select_gpu_document_processing
        ENABLE_GPU_ARIA="No"
    fi

    if [[ $IBM_LICENS == "Accept" ]]; then
        ${YQ_CMD} w -i ${CP4A_PATTERN_FILE_TMP} spec.ibm_license "accept"
    else
        ${YQ_CMD} w -i ${CP4A_PATTERN_FILE_TMP} spec.ibm_license ""
    fi
}

function apply_cp4a_operator(){
    ${COPY_CMD} -rf ${OPERATOR_FILE_BAK} ${OPERATOR_FILE_TMP}

    printf "\n"
    if [[ ("$SCRIPT_MODE" != "review") && ("$SCRIPT_MODE" != "OLM") ]]; then
        echo -e "\x1B[1mInstalling the Cloud Pak for Automation operator...\x1B[0m"
    fi
    # set db2_license
    ${SED_COMMAND} '/baw_license/{n;s/value:.*/value: accept/;}' ${OPERATOR_FILE_TMP}
    # Set operator image pull secret
    ${SED_COMMAND} "s|admin.registrykey|$DOCKER_RES_SECRET_NAME|g" ${OPERATOR_FILE_TMP}
    # Set operator image registry
    new_operator="$REGISTRY_IN_FILE\/cp\/cp4a"

    if [ "$use_entitlement" = "yes" ] ; then
        ${SED_COMMAND} "s/$REGISTRY_IN_FILE/$DOCKER_REG_SERVER/g" ${OPERATOR_FILE_TMP}

    else
        ${SED_COMMAND} "s/$new_operator/$CONVERT_LOCAL_REGISTRY_SERVER/g" ${OPERATOR_FILE_TMP}
    fi

    if [[ "${OCP_VERSION}" == "3.11" ]];then
        ${SED_COMMAND} "s/\# runAsUser\: 1001/runAsUser\: 1001/g" ${OPERATOR_FILE_TMP}
    fi

    if [[ $INSTALLATION_TYPE == "new" ]]; then
        ${CLI_CMD} delete -f ${OPERATOR_FILE_TMP} >/dev/null 2>&1
        sleep 5
    fi

    INSTALL_OPERATOR_CMD="${CLI_CMD} apply -f ${OPERATOR_FILE_TMP}"
    if $INSTALL_OPERATOR_CMD ; then
        echo -e "\x1B[1mDone\x1B[0m"
    else
        echo -e "\x1B[1;31mFailed\x1B[0m"
    fi

    ${COPY_CMD} -rf ${OPERATOR_FILE_TMP} ${OPERATOR_FILE_BAK}
    printf "\n"
    # Check deployment rollout status every 5 seconds (max 10 minutes) until complete.
    echo -e "\x1B[1mWaiting for the Cloud Pak operator to be ready. This might take a few minutes... \x1B[0m"
    ATTEMPTS=0
    ROLLOUT_STATUS_CMD="${CLI_CMD} rollout status deployment/ibm-cp4a-operator"
    until $ROLLOUT_STATUS_CMD || [ $ATTEMPTS -eq 120 ]; do
        $ROLLOUT_STATUS_CMD
        ATTEMPTS=$((ATTEMPTS + 1))
        sleep 5
    done
    if $ROLLOUT_STATUS_CMD ; then
        echo -e "\x1B[1mDone\x1B[0m"
    else
        echo -e "\x1B[1;31mFailed\x1B[0m"
    fi
    printf "\n"
}

function copy_jdbc_driver(){
    # Get pod name
    echo -e "\x1B[1mCopying the JDBC driver for the operator...\x1B[0m"
    operator_podname=$(${CLI_CMD} get pod|grep ibm-cp4a-operator|grep Running|awk '{print $1}')

    # ${CLI_CMD} exec -it ${operator_podname} -- rm -rf /opt/ansible/share/jdbc
    COPY_JDBC_CMD="${CLI_CMD} cp ${JDBC_DRIVER_DIR} ${operator_podname}:/opt/ansible/share/"

    if $COPY_JDBC_CMD ; then
        echo -e "\x1B[1mDone\x1B[0m"
    else
        echo -e "\x1B[1;31mFailed\x1B[0m"
    fi
}

function copy_sap_libraries(){
    SAP_LIBS_LIST=("libicudata.so.50" "libicudecnumber.so" "libicui18n.so.50" "libicuuc.so.50" "libsapcrypto.so" "libsapjco3.so" "libsapnwrfc.so" "sapjco3.jar" "libsapucum.so")
    # Get pod name

    echo -e "\x1B[1mCopying the SAP libraries for the operator...\x1B[0m"
    #Check if saplibs folder exists
    if [ ! -d ${SAP_LIB_DIR} ]; then
        echo -e "\x1B[1;31m\"${SAP_LIB_DIR}\" directory does not exist! Please refer to the documentation to get the SAP libraries for ICCSAP. Exiting...
Check the following KC for details--> https://www.ibm.com/support/knowledgecenter/SSYHZ8_20.0.x/com.ibm.dba.install/op_topics/tsk_deploy_demo.html \n\x1B[0m"
        exit 0
    fi

    #Check if all required SAP libs are present and print missing
    missing_libs="no"
    for file in "${SAP_LIBS_LIST[@]}"; do
        if [ ! -f ${SAP_LIB_DIR}/$file ]; then
            echo -e "\x1B[1;31m\"${SAP_LIB_DIR}/$file\" file does not exist!\n\x1B[0m"
            missing_libs="yes"
        fi
    done

    if [ $missing_libs == "yes" ]; then
        echo -e "\x1B[1;31mMissing required SAP Libraries. Please refer to the documentation to get the SAP libraries for ICCSAP. Exiting...
Check the following KC for details--> https://www.ibm.com/support/knowledgecenter/SSYHZ8_20.0.x/com.ibm.dba.install/op_topics/tsk_deploy_demo.html \n\x1B[0m"
        exit 0
    fi

    operator_podname=$(${CLI_CMD} get pod|grep ibm-cp4a-operator|grep Running|awk '{print $1}')

    #Delete existing saplibs directory from /opt/ansible/share/ before creating new one
    if [[ $INSTALLATION_TYPE == "existing" ]]; then
        ${CLI_CMD} exec -it ${operator_podname} -- rm -rf /opt/ansible/share/saplibs
    fi

    COPY_SAP_CMD="${CLI_CMD} cp ${SAP_LIB_DIR} ${operator_podname}:/opt/ansible/share/"

    if $COPY_SAP_CMD ; then
        echo -e "\x1B[1mDone\x1B[0m"
    else
        echo -e "\x1B[1;31mFailed\x1B[0m"
    fi
}


function set_foundation_components(){
    # ${COPY_CMD} -rf ${CP4A_PATTERN_FILE_BAK} ${CP4A_PATTERN_FILE_TMP}
    if (( ${#FOUNDATION_DELETE_LIST[@]} > 0 ));then
        if (( ${#OPT_COMPONENTS_CR_SELECTED[@]} > 0 ));then
            # OPT_COMPONENTS_CR_SELECTED
            OPT_COMPONENTS_CR_SELECTED_UPPERCASE=()
            x=0;while [ ${x} -lt ${#OPT_COMPONENTS_CR_SELECTED[*]} ] ; do OPT_COMPONENTS_CR_SELECTED_UPPERCASE[$x]=$(tr [a-z] [A-Z] <<< ${OPT_COMPONENTS_CR_SELECTED[$x]}); let x++; done

            for host in ${OPT_COMPONENTS_CR_SELECTED_UPPERCASE[@]}; do
                FOUNDATION_DELETE_LIST=( "${FOUNDATION_DELETE_LIST[@]/$host}" )
            done
        fi

        for item in "${FOUNDATION_DELETE_LIST[@]}"; do
            if [[ "$item" == "BAS" ]];then
                ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.bastudio_configuration
            fi
            if [[ "$item" == "UMS" ]];then
                ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.ums_configuration
                ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.datasource_configuration.dc_ums_datasource
            fi
            if [[ "$item" == "BAN" ]];then
                ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.navigator_configuration
            fi
            if [[ "$item" == "RR" ]];then
                ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.resource_registry_configuration
            fi
            if [[ "$item" == "AE" ]];then
                ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.application_engine_configuration
            fi
        done
    fi
    # ${COPY_CMD} -rf ${CP4A_PATTERN_FILE_TMP} ${CP4A_PATTERN_FILE_BAK}
}

function merge_pattern(){
    # echo "length of optional_component_cr_arr:${#optional_component_cr_arr[@]}"
    # echo "!!optional_component_cr_arr!!!${optional_component_cr_arr[*]}"
    # echo "EXISTING_PATTERN_ARR: ${EXISTING_PATTERN_ARR[*]}"
    # echo "PATTERNS_CR_SELECTED: ${PATTERNS_CR_SELECTED[*]}"
    # echo "EXISTING_OPT_COMPONENT_ARR: ${EXISTING_OPT_COMPONENT_ARR[*]}"
    # echo "OPT_COMPONENTS_CR_SELECTED: ${OPT_COMPONENTS_CR_SELECTED[*]}"
    # echo "FOUNDATION_CR_SELECTED_LOWCASE: ${FOUNDATION_CR_SELECTED_LOWCASE[*]}"
    # echo "FOUNDATION_DELETE_LIST: ${FOUNDATION_DELETE_LIST[*]}"
    # echo "OPTIONAL_COMPONENT_DELETE_LIST: ${OPTIONAL_COMPONENT_DELETE_LIST[*]}"
    # echo "KEEP_COMPOMENTS: ${KEEP_COMPOMENTS[*]}"
    # echo "REMOVED FOUNDATION_CR_SELECTED FROM OPTIONAL_COMPONENT_DELETE_LIST: ${OPTIONAL_COMPONENT_DELETE_LIST[*]}"
    # echo "pattern list in CR: ${pattern_joined}"
    # echo "optional components list in CR: ${opt_components_joined}"
    # echo "length of optional_component_arr:${#optional_component_arr[@]}"

    # read -rsn1 -p"Press any key to continue (DEBUG MODEL)";echo

    # ${COPY_CMD} -rf ${CP4A_PATTERN_FILE_BAK} ${CP4A_PATTERN_FILE_TMP}
    set_ldap_type_foundation
    for item in "${PATTERNS_CR_SELECTED[@]}"; do
        while true; do
            case $item in
                "content")
                    set_ldap_type_content_pattern
                    set_external_share_content_pattern
                    set_object_store_content_pattern
                    ${YQ_CMD} m -a -i -M ${CP4A_PATTERN_FILE_TMP} ${CONTENT_PATTERN_FILE_BAK}
                    break
                    ;;
                "contentanalyzer")
                    set_aca_tenant_pattern
                    ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.datasource_configuration.dc_ca_datasource.tenant_databases
                    ${YQ_CMD} m -a -i -M ${CP4A_PATTERN_FILE_TMP} ${ACA_PATTERN_FILE_BAK}
                    break
                    ;;
                "decisions")
                    set_decision_feature
                    ${YQ_CMD} m -a -i -M ${CP4A_PATTERN_FILE_TMP} ${DECISIONS_PATTERN_FILE_BAK}
                    break
                    ;;
                "workflow")
                    # set_ldap_type_workflow_pattern
                    if [[ "${INSTALL_BAW_ONLY}" == "Yes" ]]; then
                        # ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.baw_configuration
                        if [[ $DEPLOYMENT_TYPE == "enterprise" ]];then
                            # if [[ $INSTALLATION_TYPE == "existing" && (" ${EXISTING_PATTERN_ARR[@]} " =~ "workflow") ]]; then
                            #     ${YQ_CMD} d -i ${WORKFLOW_PATTERN_FILE_BAK} spec.datasource_configuration.dc_os_datasources
                            #     ${YQ_CMD} d -i ${WORKFLOW_PATTERN_FILE_BAK} spec.initialize_configuration
                            #     ${YQ_CMD} d -i ${WORKFLOW_PATTERN_FILE_BAK} spec.bastudio_configuration
                            #     ${YQ_CMD} d -i ${WORKFLOW_PATTERN_FILE_BAK} spec.baw_configuration
                            # fi
                            ${YQ_CMD} m -a -i -M ${CP4A_PATTERN_FILE_TMP} ${WORKFLOW_PATTERN_FILE_BAK}
                        elif [[ $DEPLOYMENT_TYPE == "demo" ]]
                        then
                            # if [[ $INSTALLATION_TYPE == "existing" && (" ${EXISTING_PATTERN_ARR[@]} " =~ "workflow") ]]; then
                            #     ${YQ_CMD} d -i ${WORKFLOW_PATTERN_FILE_BAK} spec.baw_configuration
                            # fi
                            ${YQ_CMD} m -a -i -M ${CP4A_PATTERN_FILE_TMP} ${WORKFLOW_PATTERN_FILE_BAK}
                            ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.bastudio_configuration
                        fi
                    fi
                    break
                    ;;
                "workflow-authoring")
                    # set_ldap_type_workstreams_pattern
                    if [[ "$AE_DATA_PERSISTENCE_ENABLE" == "Yes" ]]; then
                        enable_ae_data_persistence_workflow_authoring
                    fi
                    ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.baw_configuration


                    if [[ $DEPLOYMENT_TYPE == "enterprise" ]];then
                        # if [[ $INSTALLATION_TYPE == "existing" && (" ${EXISTING_PATTERN_ARR[@]} " =~ "workflow-authoring") ]]; then
                        #     ${YQ_CMD} d -i ${WORKFLOW_AUTHOR_PATTERN_FILE_BAK} spec.datasource_configuration.dc_os_datasources
                        #     ${YQ_CMD} d -i ${WORKFLOW_AUTHOR_PATTERN_FILE_BAK} spec.initialize_configuration
                        #     ${YQ_CMD} d -i ${WORKFLOW_AUTHOR_PATTERN_FILE_BAK} spec.bastudio_configuration
                        # fi
                        ${YQ_CMD} m -a -i -M ${CP4A_PATTERN_FILE_TMP} ${WORKFLOW_AUTHOR_PATTERN_FILE_BAK}
                    fi
                    break
                    ;;
                "workflow-runtime")
                    # set_ldap_type_workstreams_pattern
                    if [[ $DEPLOYMENT_TYPE == "enterprise" ]];then
                        if [[ " ${PATTERNS_CR_SELECTED[@]} " =~ "workstreams" && " ${PATTERNS_CR_SELECTED[@]} " =~ "workflow-runtime" ]]; then
                            break
                        else
                            # if [[ $INSTALLATION_TYPE == "existing" ]]; then
                            #     ${YQ_CMD} d -i ${WORKFLOW_PATTERN_FILE_BAK} spec.baw_configuration
                            # fi
                            # if [[ " ${EXISTING_PATTERN_ARR[@]} " =~ "workflow-runtime" ]]; then
                            #     ${YQ_CMD} d -i ${WORKFLOW_PATTERN_FILE_BAK} spec.datasource_configuration.dc_os_datasources
                            #     ${YQ_CMD} d -i ${WORKFLOW_PATTERN_FILE_BAK} spec.initialize_configuration
                            # fi
                            ${YQ_CMD} m -a -i -M ${CP4A_PATTERN_FILE_TMP} ${WORKFLOW_PATTERN_FILE_BAK}
                        fi
                    elif [[ $DEPLOYMENT_TYPE == "demo" ]]
                    then
                        ${YQ_CMD} m -a -i -M ${CP4A_PATTERN_FILE_TMP} ${WORKFLOW_PATTERN_FILE_BAK}
                        ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.bastudio_configuration
                    fi
                    break
                    ;;
                "workstreams")
                    # set_ldap_type_workstreams_pattern
                    if [[ " ${PATTERNS_CR_SELECTED[@]} " =~ "workstreams" && " ${PATTERNS_CR_SELECTED[@]} " =~ "workflow-runtime" ]]; then
                        break
                    else
                        # if [[ $INSTALLATION_TYPE == "existing" ]]; then
                        #     ${YQ_CMD} d -i ${WORKSTREAMS_PATTERN_FILE_BAK} spec.baw_configuration
                        # fi
                        # if [[ " ${EXISTING_PATTERN_ARR[@]} " =~ "workstreams" ]]; then
                        #     ${YQ_CMD} d -i ${WORKSTREAMS_PATTERN_FILE_BAK} spec.datasource_configuration.dc_os_datasources
                        #     ${YQ_CMD} d -i ${WORKSTREAMS_PATTERN_FILE_BAK} spec.initialize_configuration
                        # fi
                        ${YQ_CMD} m -a -i -M ${CP4A_PATTERN_FILE_TMP} ${WORKSTREAMS_PATTERN_FILE_BAK}
                    fi
                    break
                    ;;
                "workflow-workstreams")
                    # set_ldap_type_ww_pattern
                    # ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.baw_configuration
                    if [[ $DEPLOYMENT_TYPE == "enterprise" ]];then
                        if [[ $INSTALLATION_TYPE == "existing" ]]; then
                            # if [[ !(" ${EXISTING_PATTERN_ARR[@]} " =~ "workstreams") && (" ${EXISTING_PATTERN_ARR[@]} " =~ "workflow-runtime") ]]; then
                            #     ${YQ_CMD} d -i ${WORKSTREAMS_PATTERN_FILE_BAK} spec.datasource_configuration.dc_os_datasources.[1]
                            #     ${YQ_CMD} d -i ${WORKSTREAMS_PATTERN_FILE_BAK} spec.initialize_configuration.ic_ldap_creation
                            #     ${YQ_CMD} d -i ${WORKSTREAMS_PATTERN_FILE_BAK} spec.initialize_configuration.ic_obj_store_creation.object_stores.[1]
                            #     ${YQ_CMD} m -a -i -M ${CP4A_PATTERN_FILE_TMP} ${WORKSTREAMS_PATTERN_FILE_BAK}
                            # elif [[ (" ${EXISTING_PATTERN_ARR[@]} " =~ "workstreams") && !(" ${EXISTING_PATTERN_ARR[@]} " =~ "workflow-runtime") ]]
                            # then
                            #     ${YQ_CMD} d -i ${WORKFLOW_PATTERN_FILE_BAK} spec.datasource_configuration.dc_os_datasources.[3]
                            #     ${YQ_CMD} d -i ${WORKFLOW_PATTERN_FILE_BAK} spec.initialize_configuration.ic_ldap_creation
                            #     ${YQ_CMD} d -i ${WORKFLOW_PATTERN_FILE_BAK} spec.initialize_configuration.ic_obj_store_creation.object_stores.[3]
                            #     ${YQ_CMD} m -a -i -M ${CP4A_PATTERN_FILE_TMP} ${WORKFLOW_PATTERN_FILE_BAK}
                            # fi
                            ${YQ_CMD} m -a -i -M ${CP4A_PATTERN_FILE_TMP} ${WW_PATTERN_FILE_BAK}
                        else
                            ${YQ_CMD} m -a -i -M ${CP4A_PATTERN_FILE_TMP} ${WW_PATTERN_FILE_BAK}

                        fi
                    elif [[ $DEPLOYMENT_TYPE == "demo" ]]
                    then
                        ${YQ_CMD} m -a -i -M ${CP4A_PATTERN_FILE_TMP} ${WW_PATTERN_FILE_BAK}
                        # ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.bastudio_configuration
                    fi
                    break
                    ;;
                "application")
                    set_baa_app_designer
                    if [[ "$AE_DATA_PERSISTENCE_ENABLE" == "Yes" ]]; then
                        enable_ae_data_persistence_baa
                    fi
                    ${YQ_CMD} m -a -i -M ${CP4A_PATTERN_FILE_TMP} ${APPLICATION_PATTERN_FILE_BAK}
                    break
                    ;;
                "digitalworker")
                    ${YQ_CMD} m -a -i -M ${CP4A_PATTERN_FILE_TMP} ${ADW_PATTERN_FILE_BAK}
                    break
                    ;;
                "decisions_ads")
                    set_ads_designer_runtime
                    ${YQ_CMD} m -a -i -M ${CP4A_PATTERN_FILE_TMP} ${ADS_PATTERN_FILE_BAK}
                    break
                    ;;
                "document_processing")
                    set_aria_gpu
                    ${YQ_CMD} m -a -i -M ${CP4A_PATTERN_FILE_TMP} ${ARIA_PATTERN_FILE_BAK}
                    break
                    ;;
                "document_processing_runtime")
                    break
                    ;;
                "document_processing_designer")
                    break
                    ;;
            esac
        done
    done
}

function merge_optional_components(){
    # ${COPY_CMD} -rf ${CP4A_PATTERN_FILE_BAK} ${CP4A_PATTERN_FILE_TMP}

    for item in "${OPTIONAL_COMPONENT_DELETE_LIST[@]}"; do
        while true; do
            case $item in
                "bas")
                    ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.bastudio_configuration
                    break
                    ;;
                "ums")
                    containsElement "bai" "${optional_component_cr_arr[@]}"
                    retVal=$?
                    if [[ $retVal -eq 1 ]]; then
                        ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.ums_configuration
                        ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.datasource_configuration.dc_ums_datasource
                    fi
                    break
                    ;;
                "cmis")
                    ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.ecm_configuration.cmis
                    break
                    ;;
                "css")
                    break
                    ;;
                "es")
                    ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.ecm_configuration.es
                    break
                    ;;
                "tm")
                    ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.ecm_configuration.tm
                    break
                    ;;
                "ier")
                    ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.ier_configuration
                    break
                    ;;
                "iccsap")
                    ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.iccsap_configuration
                    break
                    ;;
                "bai")
                    if [[ (" ${PATTERNS_CR_SELECTED[@]} " =~ "workflow-runtime") && (" ${PATTERNS_CR_SELECTED[@]} " =~ "workstreams") ]]; then
                        break
                    else
                        ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.bai_configuration
                        ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.shared_configuration.kafka_configuration
                        break
                    fi
                    ;;
                "ads_designer")
                    break
                    ;;
                "ads_runtime")
                    break
                    ;;
                "decisionCenter")
                    break
                    ;;
                "decisionRunner")
                    break
                    ;;
                "decisionServerRuntime")
                    break
                    ;;
                "app_designer")
                    break
                    ;;
                "ae_data_persistence")
                    break
                    ;;
                "baw_authoring")
                    break
                    ;;
                "auto_service")
                    break
                    ;;
                "document_processing_designer")
                    break
                    ;;
                "document_processing_runtime")
                    break
                    ;;
            esac
        done
    done
    FOUNDATION_CR_SELECTED=($(echo "${foundation_component_arr[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    # FOUNDATION_CR_SELECTED_LOWCASE=( "${FOUNDATION_CR_SELECTED[@],,}" )

    x=0;while [ ${x} -lt ${#FOUNDATION_CR_SELECTED[*]} ] ; do FOUNDATION_CR_SELECTED_LOWCASE[$x]=$(tr [A-Z] [a-z] <<< ${FOUNDATION_CR_SELECTED[$x]}); let x++; done
    FOUNDATION_DELETE_LIST=($(echo "${FOUNDATION_CR_SELECTED[@]}" "${FOUNDATION_FULL_ARR[@]}" | tr ' ' '\n' | sort | uniq -u))

    # ${COPY_CMD} -rf ${CP4A_PATTERN_FILE_TMP} ${CP4A_PATTERN_FILE_BAK}
}

function get_existing_pattern_name(){
    existing_pattern_cr_name=""
    existing_pattern_list=""
    existing_opt_component_list=""
    existing_platform_type=""
    existing_deployment_type=""
    printf "\x1B[1mProvide the path and file name to the existing custom resource (CR)?\n\x1B[0m"
    printf "\x1B[1mPress [Enter] to accept default.\n\x1B[0m"
    # printf "\x1B[1mDefault is \x1B[0m(${CP4A_PATTERN_FILE_BAK}): "
    # existing_pattern_cr_name=`${CLI_CMD} get icp4acluster|awk '{if(NR>1){if(NR==2){ arr=$1; }else{ arr=arr" "$1; }} } END{ print arr }'`

    while [[ $existing_pattern_cr_name == "" ]];
    do
        read -p "[Default=$CP4A_PATTERN_FILE_BAK]: " existing_pattern_cr_name
        : ${existing_pattern_cr_name:=$CP4A_PATTERN_FILE_BAK}
        if [ -f "$existing_pattern_cr_name" ]; then
            existing_pattern_list=`cat $existing_pattern_cr_name | ${YQ_CMD} r - spec.shared_configuration.sc_deployment_patterns`
            existing_opt_component_list=`cat $existing_pattern_cr_name | ${YQ_CMD} r - spec.shared_configuration.sc_optional_components`

            existing_platform_type=`cat $existing_pattern_cr_name | ${YQ_CMD} r - spec.shared_configuration.sc_deployment_platform`
            existing_deployment_type=`cat $existing_pattern_cr_name | ${YQ_CMD} r - spec.shared_configuration.sc_deployment_type`


            case "${existing_deployment_type}" in
                demo*)     DEPLOYMENT_TYPE="demo";;
                enterprise*)    DEPLOYMENT_TYPE="enterprise";;
                *)
                    echo -e "\x1B[1;31mNot valid deployment type found in CR, exiting....\n\x1B[0m"
                    exit 0
                    ;;
            esac

            case "${existing_platform_type}" in
                ROKS*)     PLATFORM_SELECTED="ROKS";;
                OCP*)    PLATFORM_SELECTED="OCP";;
                other*)     PLATFORM_SELECTED="other";;
                *)
                    echo -e "\x1B[1;31mNot valid platform type found in CR, exiting....\n\x1B[0m"
                    exit 0
                    ;;
            esac
            OIFS=$IFS
            IFS=',' read -r -a EXISTING_PATTERN_ARR <<< "$existing_pattern_list"
            IFS=$OIFS

            OIFS=$IFS
            IFS=',' read -r -a EXISTING_OPT_COMPONENT_ARR <<< "$existing_opt_component_list"
            IFS=$OIFS

            FOUNDATION_PATTERN_FILE=${PARENT_DIR}/install/cert-kubernetes/descriptors/patterns/ibm_cp4a_cr_${DEPLOYMENT_TYPE}_foundation.yaml
            if [[ "$existing_pattern_cr_name" == "$CP4A_PATTERN_FILE_BAK" ]]; then
                ${COPY_CMD} -rf "${CP4A_PATTERN_FILE_BAK}" "${CP4A_EXISTING_BAK}"
                ${COPY_CMD} -rf "${CP4A_PATTERN_FILE_BAK}" "${CP4A_EXISTING_TMP}"
            else
                ${COPY_CMD} -rf "${existing_pattern_cr_name}" "${CP4A_PATTERN_FILE_BAK}"
                ${COPY_CMD} -rf "${existing_pattern_cr_name}" "${CP4A_EXISTING_BAK}"
                ${COPY_CMD} -rf "${existing_pattern_cr_name}" "${CP4A_EXISTING_TMP}"
            fi
            # ${COPY_CMD} -rf "${FOUNDATION_PATTERN_FILE}" "${CP4A_PATTERN_FILE_TMP}"
            # ${YQ_CMD} m -a -i -M ${CP4A_PATTERN_FILE_TMP} ${CP4A_PATTERN_FILE_BAK}
            # ${COPY_CMD} -rf "${CP4A_PATTERN_FILE_BAK}" "${CP4A_PATTERN_FILE_TMP}"
        else
            echo -e "\x1B[1;31m\"$existing_pattern_cr_name\" file does not exist! \n\x1B[0m"
            existing_pattern_cr_name=""
        fi
    done
    # existing_pattern_list=`${CLI_CMD} get icp4acluster $existing_pattern_cr_name -o yaml | yq r - spec.shared_configuration.sc_deployment_patterns`
    # existing_pattern_deploy_type=`${CLI_CMD} get icp4acluster $existing_pattern_cr_name -o yaml | yq r - spec.shared_configuration.sc_deployment_type`

    if [[ (" ${EXISTING_PATTERN_ARR[@]} " =~ "workflow") && (" ${EXISTING_OPT_COMPONENT_ARR[@]} " =~ "baw_authoring") ]]; then
        EXISTING_PATTERN_ARR=( "${EXISTING_PATTERN_ARR[@]}" "workflow-authoring" )
    fi

    if [[ (" ${EXISTING_PATTERN_ARR[@]} " =~ "workflow") && !(" ${EXISTING_OPT_COMPONENT_ARR[@]} " =~ "baw_authoring") && ($retVal_baw -eq 1) ]]; then
        EXISTING_PATTERN_ARR=( "${EXISTING_PATTERN_ARR[@]}" "workflow-runtime" )
    fi

    if [[ (" ${EXISTING_PATTERN_ARR[@]} " =~ "document_processing") && (" ${EXISTING_OPT_COMPONENT_ARR[@]} " =~ "document_processing_designer") ]]; then
        EXISTING_PATTERN_ARR=( "${EXISTING_PATTERN_ARR[@]}" "document_processing_designer" )
    fi

    if [[ (" ${EXISTING_PATTERN_ARR[@]} " =~ "document_processing") && (" ${EXISTING_OPT_COMPONENT_ARR[@]} " =~ "document_processing_runtime") ]]; then
        EXISTING_PATTERN_ARR=( "${EXISTING_PATTERN_ARR[@]}" "document_processing_runtime" )
    fi

    if [[ (" ${EXISTING_PATTERN_ARR[@]} " =~ "workflow-workstreams") && ("${DEPLOYMENT_TYPE}" == "enterprise") ]]; then
        echo -e "\x1B[1;31mYou are updating existing patterns including workflow-workstreams which is not supported.\x1B[0m"
        echo -e "\x1B[1;31mRefer to the documentation to upgrade or add another pattern manually.\x1B[0m"
        echo -e "\x1B[1;31mexiting...\x1B[0m"
        read -rsn1 -p"Press any key to exit";echo
        exit 1
    fi
}

function select_objectstore_number(){
    content_os_number=""
    # while [[ $content_os_number == "" ]];
    # do
    while true; do
        printf "\n"
        printf "\x1B[1mHow many object stores is being deployed? \x1B[0m"
        read -rp "" content_os_number
        [[ $content_os_number =~ ^[0-9]+$ ]] || { echo -e "\x1B[1;31mEnter a valid number [1 to 10]\x1B[0m"; continue; }
        if [ "$content_os_number" -ge 1 ] && [ "$content_os_number" -le 10 ]; then
            break
        else
            echo -e "\x1B[1;31mEnter a valid number [1 to 10]\x1B[0m"
            content_os_number=""
        fi
    done
}

function select_gpu_document_processing(){
    printf "\n"
    printf "\x1B[1mAre there GPU enabled worker nodes (Yes/No)? \x1B[0m"
    set_gpu_enabled=""
    ENABLE_GPU_ARIA=""
    while [[ $set_gpu_enabled == "" ]];
    do
        read -rp "" set_gpu_enabled
        case "$set_gpu_enabled" in
        "y"|"Y"|"yes"|"Yes"|"YES")
            ENABLE_GPU_ARIA="Yes"
            break
            ;;
        "n"|"N"|"no"|"No"|"NO")
            ENABLE_GPU_ARIA="No"
            break
            ;;
        *)
            echo -e "Answer must be \"Yes\" or \"No\"\n"
            set_gpu_enabled=""
            ENABLE_GPU_ARIA=""
            ;;
        esac
    done
    if [[ "${ENABLE_GPU_ARIA}" == "Yes" ]]; then
        printf "\n"
        printf "\x1B[1mWhat is the node label key used to identify the GPU worker node(s)? \x1B[0m"
        nodelabel_key=""
        while [[ $nodelabel_key == "" ]];
        do
            read -rp "" nodelabel_key
            if [ -z "$nodelabel_key" ]; then
            echo -e "\x1B[1;31mEnter the node label key.\x1B[0m"
            fi
        done

        printf "\n"
        printf "\x1B[1mWhat is the node label value used to identify the GPU worker node(s)? \x1B[0m"
        nodelabel_value=""
        while [[ $nodelabel_value == "" ]];
        do
            read -rp "" nodelabel_value
            if [ -z "$nodelabel_value" ]; then
            echo -e "\x1B[1;31mEnter the node label value.\x1B[0m"
            fi
        done
    fi
}

function set_baa_app_designer(){
    ${COPY_CMD} -rf ${APPLICATION_PATTERN_FILE_BAK} ${APPLICATION_PATTERN_FILE_TMP}
    if [[ $DEPLOYMENT_TYPE == "demo"  ]] ;
    then
        foundation_baa=("BAS")
        foundation_component_arr=( "${foundation_component_arr[@]}" "${foundation_baa[@]}" )

    elif [[ $DEPLOYMENT_TYPE == "enterprise" ]]
    then
        containsElement "app_designer" "${OPT_COMPONENTS_CR_SELECTED[@]}"
        retVal=$?
        if [[ $retVal -eq 0 ]]; then
            foundation_baa=("BAS")
            foundation_component_arr=( "${foundation_component_arr[@]}" "${foundation_baa[@]}" )
        fi
    fi
    ${COPY_CMD} -rf ${APPLICATION_PATTERN_FILE_TMP} ${APPLICATION_PATTERN_FILE_BAK}
}

function set_ads_designer_runtime(){
    ${COPY_CMD} -rf ${ADS_PATTERN_FILE_BAK} ${ADS_PATTERN_FILE_TMP}
    if [[ $DEPLOYMENT_TYPE == "demo"  ]] ;
    then
        ${YQ_CMD} w -i ${ADS_PATTERN_FILE_TMP} spec.ads_configuration.decision_designer.enabled "true"
        ${YQ_CMD} w -i ${ADS_PATTERN_FILE_TMP} spec.ads_configuration.decision_runtime.enabled "true"
        foundation_ads=("BAS")
        foundation_component_arr=( "${foundation_component_arr[@]}" "${foundation_ads[@]}" )

    elif [[ $DEPLOYMENT_TYPE == "enterprise" ]]
    then
        containsElement "ads_designer" "${OPT_COMPONENTS_CR_SELECTED[@]}"
        retVal=$?
        if [[ $retVal -eq 0 ]]; then
            ${YQ_CMD} w -i ${ADS_PATTERN_FILE_TMP} spec.ads_configuration.decision_designer.enabled "true"
            foundation_ads=("BAS")
            foundation_component_arr=( "${foundation_component_arr[@]}" "${foundation_ads[@]}" )
        else
            ${YQ_CMD} w -i ${ADS_PATTERN_FILE_TMP} spec.ads_configuration.decision_designer.enabled "false"
        fi
        containsElement "ads_runtime" "${OPT_COMPONENTS_CR_SELECTED[@]}"
        retVal=$?
        if [[ $retVal -eq 0 ]]; then
            ${YQ_CMD} w -i ${ADS_PATTERN_FILE_TMP} spec.ads_configuration.decision_runtime.enabled "true"
        else
            ${YQ_CMD} w -i ${ADS_PATTERN_FILE_TMP} spec.ads_configuration.decision_runtime.enabled "false"
        fi

    fi
    ${COPY_CMD} -rf ${ADS_PATTERN_FILE_TMP} ${ADS_PATTERN_FILE_BAK}
}


function set_decision_feature(){
    ${COPY_CMD} -rf ${DECISIONS_PATTERN_FILE_BAK} ${DECISIONS_PATTERN_FILE_TMP}
    if [[ $DEPLOYMENT_TYPE == "demo"  ]] ;
    then
        ${YQ_CMD} w -i ${DECISIONS_PATTERN_FILE_TMP} spec.odm_configuration.decisionCenter.enabled "true"
        ${YQ_CMD} w -i ${DECISIONS_PATTERN_FILE_TMP} spec.odm_configuration.decisionServerRuntime.enabled "true"
        ${YQ_CMD} w -i ${DECISIONS_PATTERN_FILE_TMP} spec.odm_configuration.decisionRunner.enabled "true"
    elif [[ $DEPLOYMENT_TYPE == "enterprise" ]]
    then
        containsElement "decisionCenter" "${OPT_COMPONENTS_CR_SELECTED[@]}"
        retVal=$?
        if [[ $retVal -eq 0 ]]; then
            ${YQ_CMD} w -i ${DECISIONS_PATTERN_FILE_TMP} spec.odm_configuration.decisionCenter.enabled "true"
        else
            ${YQ_CMD} w -i ${DECISIONS_PATTERN_FILE_TMP} spec.odm_configuration.decisionCenter.enabled "false"
        fi
        containsElement "decisionServerRuntime" "${OPT_COMPONENTS_CR_SELECTED[@]}"
        retVal=$?
        if [[ $retVal -eq 0 ]]; then
            ${YQ_CMD} w -i ${DECISIONS_PATTERN_FILE_TMP} spec.odm_configuration.decisionServerRuntime.enabled "true"
        else
            ${YQ_CMD} w -i ${DECISIONS_PATTERN_FILE_TMP} spec.odm_configuration.decisionServerRuntime.enabled "false"
        fi
        containsElement "decisionRunner" "${OPT_COMPONENTS_CR_SELECTED[@]}"
        retVal=$?
        if [[ $retVal -eq 0 ]]; then
            ${YQ_CMD} w -i ${DECISIONS_PATTERN_FILE_TMP} spec.odm_configuration.decisionRunner.enabled "true"
        else
            ${YQ_CMD} w -i ${DECISIONS_PATTERN_FILE_TMP} spec.odm_configuration.decisionRunner.enabled "false"
        fi
    fi
    ${COPY_CMD} -rf ${DECISIONS_PATTERN_FILE_TMP} ${DECISIONS_PATTERN_FILE_BAK}
}

function set_aria_gpu(){
    ${COPY_CMD} -rf ${ARIA_PATTERN_FILE_BAK} ${ARIA_PATTERN_FILE_TMP}
    if [[ ($DEPLOYMENT_TYPE == "enterprise" && (" ${PATTERNS_CR_SELECTED[@]} " =~ "document_processing_designer")) || $DEPLOYMENT_TYPE == "demo" ]] ;
    then
        if [[ "$ENABLE_GPU_ARIA" == "Yes" ]]; then
            ${YQ_CMD} w -i ${ARIA_PATTERN_FILE_TMP} spec.ca_configuration.deeplearning.gpu_enabled "true"
            ${YQ_CMD} w -i ${ARIA_PATTERN_FILE_TMP} spec.ca_configuration.deeplearning.nodelabel_key "$nodelabel_key"
            ${YQ_CMD} w -i ${ARIA_PATTERN_FILE_TMP} spec.ca_configuration.deeplearning.nodelabel_value "$nodelabel_value"
        elif [[ "$ENABLE_GPU_ARIA" == "No" ]]
        then
            ${YQ_CMD} w -i ${ARIA_PATTERN_FILE_TMP} spec.ca_configuration.deeplearning.gpu_enabled "false"
        fi
    fi
    ${COPY_CMD} -rf ${ARIA_PATTERN_FILE_TMP} ${ARIA_PATTERN_FILE_BAK}
}

# Begin - Modify FOUNDATION pattern yaml according patterns/components selected
function apply_pattern_cr(){
    # echo "length of optional_component_cr_arr:${#optional_component_cr_arr[@]}"
    # echo "!!optional_component_cr_arr!!!${optional_component_cr_arr[*]}"
    # echo "EXISTING_PATTERN_ARR: ${EXISTING_PATTERN_ARR[*]}"
    # echo "PATTERNS_CR_SELECTED: ${PATTERNS_CR_SELECTED[*]}"
    # echo "EXISTING_OPT_COMPONENT_ARR: ${EXISTING_OPT_COMPONENT_ARR[*]}"
    # echo "OPT_COMPONENTS_CR_SELECTED: ${OPT_COMPONENTS_CR_SELECTED[*]}"
    # echo "FOUNDATION_CR_SELECTED_LOWCASE: ${FOUNDATION_CR_SELECTED_LOWCASE[*]}"
    # echo "FOUNDATION_DELETE_LIST: ${FOUNDATION_DELETE_LIST[*]}"
    # echo "OPTIONAL_COMPONENT_DELETE_LIST: ${OPTIONAL_COMPONENT_DELETE_LIST[*]}"
    # echo "KEEP_COMPOMENTS: ${KEEP_COMPOMENTS[*]}"
    # echo "REMOVED FOUNDATION_CR_SELECTED FROM OPTIONAL_COMPONENT_DELETE_LIST: ${OPTIONAL_COMPONENT_DELETE_LIST[*]}"
    # echo "pattern list in CR: ${pattern_joined}"
    # echo "optional components list in CR: ${opt_components_joined}"
    # echo "length of optional_component_arr:${#optional_component_arr[@]}"

    # read -rsn1 -p"Press any key to continue (DEBUG MODEL)";echo

    # ${COPY_CMD} -rf ${CP4A_PATTERN_FILE_BAK} ${CP4A_PATTERN_FILE_TMP}
    # remove merge issue
    ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} metadata.labels.app.*
    # if [[ $INSTALLATION_TYPE == "existing" ]]; then
    #     ae_instance=`cat $CP4A_EXISTING_BAK | ${YQ_CMD} r - spec.application_engine_configuration.[0].name`
    #     if [[ ! -z "$ae_instance" ]]; then
    #         # read -rsn1 -p"Press any key to continue $ae_instance";echo
    #         ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.application_engine_configuration
    #     fi
    # fi
    # Keep existing value
    if [[ "${INSTALLATION_TYPE}" == "existing" ]]; then
        # read -rsn1 -p"Before Merge: Press any key to continue";echo
        ${YQ_CMD} d -i ${CP4A_EXISTING_TMP} spec.shared_configuration.sc_deployment_patterns
        ${YQ_CMD} d -i ${CP4A_EXISTING_TMP} spec.shared_configuration.sc_optional_components
        ${SED_COMMAND} '/tag: /d' ${CP4A_EXISTING_TMP}
        ${SED_COMMAND} '/appVersion: /d' ${CP4A_EXISTING_TMP}
        ${SED_COMMAND} '/release: /d' ${CP4A_EXISTING_TMP}
        # ${YQ_CMD} m -a -i -M ${CP4A_EXISTING_BAK} ${CP4A_PATTERN_FILE_TMP}
        # ${COPY_CMD} -rf ${CP4A_EXISTING_BAK} ${CP4A_PATTERN_FILE_TMP}
        # ${YQ_CMD} m -a -i -M ${CP4A_PATTERN_FILE_TMP} ${CP4A_EXISTING_BAK}
        # read -rsn1 -p"After Merge: Press any key to continue";echo
    fi

    ${SED_COMMAND_FORMAT} ${CP4A_PATTERN_FILE_TMP}
    # ${COPY_CMD} -rf ${CP4A_PATTERN_FILE_TMP} ${CP4A_PATTERN_FILE_BAK}

    tps=" ${OPTIONAL_COMPONENT_DELETE_LIST[*]} "
    for item in ${KEEP_COMPOMENTS[@]}; do
        tps=${tps/ ${item} / }
    done
    OPTIONAL_COMPONENT_DELETE_LIST=( $tps )
    # Convert pattern array to pattern list by common
    delim=""
    pattern_joined=""
    for item in "${PATTERNS_CR_SELECTED[@]}"; do
        if [[ "${DEPLOYMENT_TYPE}" == "demo" ]]; then
            pattern_joined="$pattern_joined$delim$item"
            delim=","
        elif [[ ${DEPLOYMENT_TYPE} == "enterprise" ]]
        then
            case "$item" in
            "workflow-authoring"|"workflow-runtime"|"workflow-workstreams"|"document_processing_designer"|"document_processing_runtime")
                ;;
            *)
                pattern_joined="$pattern_joined$delim$item"
                delim=","
                ;;
            esac
        fi
    done

    pattern_joined="foundation$delim$pattern_joined"
    # if [[ $INSTALL_BAW_IAWS == "No" ]];then
    #     pattern_joined="foundation$delim$pattern_joined"
    # fi
    # Convert optional components array to list by common
    delim=""
    opt_components_joined=""
    for item in "${OPT_COMPONENTS_CR_SELECTED[@]}"; do
        opt_components_joined="$opt_components_joined$delim$item"
        delim=","
    done

    merge_pattern
    merge_optional_components
    set_foundation_components

    if [[ $INSTALLATION_TYPE == "existing" ]]; then
        if [[ (" ${EXISTING_PATTERN_ARR[@]} " =~ "workflow-authoring") && !(" ${PATTERNS_CR_SELECTED[@]} " =~ "workflow-authoring") ]]; then
            # Delete Object Store for BAW Authoring
            object_array=("BAWDOCS" "BAWDOS" "BAWTOS")
        elif [[ (" ${EXISTING_PATTERN_ARR[@]} " =~ "workflow-runtime") && !(" ${PATTERNS_CR_SELECTED[@]} " =~ "workflow-runtime") ]]; then
            # Delete Object Store for BAW Runtime
            object_array=("BAWINS1DOCS" "BAWINS1DOS" "BAWINS1TOS")
        elif [[ (" ${EXISTING_PATTERN_ARR[@]} " =~ "workstreams") && !(" ${PATTERNS_CR_SELECTED[@]} " =~ "workstreams") ]]; then
            # Delete Object Store for workstreams
            object_array=("AWSINS1DOCS")
        else
            object_array=()
        fi
        if (( ${#object_array[@]} >= 1 ));then 
            for object_name in "${object_array[@]}"
            do
                containsObjectStore "$object_name" "${CP4A_EXISTING_TMP}"
                if (( ${#os_index_array[@]} >= 1 ));then
                    # ((index_array_temp=${#os_index_array[@]}-1))
                    for ((j=0;j<${#os_index_array[@]};j++))
                    do 
                        index_os=${os_index_array[$j]}
                        ${YQ_CMD} d -i ${CP4A_EXISTING_TMP} spec.datasource_configuration.dc_os_datasources.[$index_os]
                    done
                fi
                containsInitObjectStore "$object_name" "${CP4A_EXISTING_TMP}"
                if (( ${#os_index_array[@]} >= 1 ));then
                    # ((index_array_temp=${#os_index_array[@]}-1))
                    for ((j=0;j<${#os_index_array[@]};j++)) 
                    do 
                        index_os=${os_index_array[$j]}
                        ${YQ_CMD} d -i ${CP4A_EXISTING_TMP} spec.initialize_configuration.ic_obj_store_creation.object_stores.[$index_os]
                    done
                fi
            done
            object_array=()
        fi
        if [[ (" ${EXISTING_PATTERN_ARR[@]} " =~ "content") && !(" ${PATTERNS_CR_SELECTED[@]} " =~ "content") ]]; then
            # Delete Object Store for FNCM
            object_array=("FNOS1DS" "FNOS2DS" "FNOS3DS" "FNOS4DS" "FNOS5DS" "FNOS6DS" "FNOS7DS" "FNOS8DS" "FNOS9DS" "FNOS10DS")
        else
            object_array=()
        fi
        if (( ${#object_array[@]} >= 1 ));then 
            for object_name in "${object_array[@]}"
            do
                containsObjectStore "$object_name" "${CP4A_EXISTING_TMP}"
                if (( ${#os_index_array[@]} >= 1 ));then
                    # ((index_array_temp=${#os_index_array[@]}-1))
                    for ((j=0;j<${#os_index_array[@]};j++))
                    do 
                        index_os=${os_index_array[$j]}
                        ${YQ_CMD} d -i ${CP4A_EXISTING_TMP} spec.datasource_configuration.dc_os_datasources.[$index_os]
                    done
                fi
            done
            object_array=()
        fi

        if [[ (" ${EXISTING_PATTERN_ARR[@]} " =~ "workflow") && !(" ${PATTERNS_CR_SELECTED[@]} " =~ "workflow") ]]; then
            # Delete BAW Instance
            baw_name_array=("bawins1")
        elif [[ (" ${EXISTING_PATTERN_ARR[@]} " =~ "workstreams") && !(" ${PATTERNS_CR_SELECTED[@]} " =~ "workstreams") ]]; then
            baw_name_array=("awsins1")
        else
            baw_name_array=()
        fi
        if (( ${#baw_name_array[@]} >= 1 ));then 
            for object_name in "${baw_name_array[@]}"
            do
                containsBAWInstance "$object_name" "${CP4A_EXISTING_TMP}"
                if (( ${#baw_index_array[@]} >= 1 ));then
                    # ((index_array_temp=${#baw_index_array[@]}-1))
                    for ((j=0;j<${#baw_index_array[@]};j++))
                    do 
                        index_os=${baw_index_array[$j]}
                        ${YQ_CMD} d -i ${CP4A_EXISTING_TMP} spec.baw_configuration
                    done
                fi
            done
            baw_name_array=()
        fi
        # read -rsn1 -p"Before:Press any key to exit";echo
        ${YQ_CMD} m -i -a -M --overwrite --autocreate=false ${CP4A_PATTERN_FILE_TMP} ${CP4A_EXISTING_TMP}
        # read -rsn1 -p"After:Press any key to exit";echo
    fi

    # ${COPY_CMD} -rf ${CP4A_PATTERN_FILE_BAK} ${CP4A_PATTERN_FILE_TMP}
    if [[ " ${OPT_COMPONENTS_CR_SELECTED[@]} " =~ "ae_data_persistence" ]]; then
        ${YQ_CMD} w -i ${CP4A_PATTERN_FILE_TMP} spec.shared_configuration.sc_content_initialization "true"
    fi

    if [[ "$CPE_FULL_STORAGE" == "Yes" ]]; then
        ${YQ_CMD} w -i ${CP4A_PATTERN_FILE_TMP} spec.shared_configuration.sc_cpe_limited_storage "false"
    elif [[ "$CPE_FULL_STORAGE" == "No" ]]; then
        ${YQ_CMD} w -i ${CP4A_PATTERN_FILE_TMP} spec.shared_configuration.sc_cpe_limited_storage "true"
    else
        ${YQ_CMD} w -i ${CP4A_PATTERN_FILE_TMP} spec.shared_configuration.sc_cpe_limited_storage "false"
    fi

    # Set sc_deployment_patterns
    ${SED_COMMAND} "s|sc_deployment_patterns:.*|sc_deployment_patterns: \"$pattern_joined\"|g" ${CP4A_PATTERN_FILE_TMP}

    # Set sc_optional_components='' when none optional component selected
    if [ "${#optional_component_cr_arr[@]}" -eq "0" ]; then
        ${SED_COMMAND} "s|sc_optional_components:.*|sc_optional_components: \"\"|g" ${CP4A_PATTERN_FILE_TMP}
    else
        ${SED_COMMAND} "s|sc_optional_components:.*|sc_optional_components: \"$opt_components_joined\"|g" ${CP4A_PATTERN_FILE_TMP}
    fi

    # Set sc_deployment_platform
    ${SED_COMMAND} "s|sc_deployment_platform:.*|sc_deployment_platform: \"$PLATFORM_SELECTED\"|g" ${CP4A_PATTERN_FILE_TMP}

    # Set sc_deployment_type
    ${SED_COMMAND} "s|sc_deployment_type:.*|sc_deployment_type: \"$DEPLOYMENT_TYPE\"|g" ${CP4A_PATTERN_FILE_TMP}


    # Set sc_deployment_hostname_suffix
    if  [[ $PLATFORM_SELECTED == "OCP" || $PLATFORM_SELECTED == "ROKS" ]];
    then
        ${SED_COMMAND} "s|sc_deployment_hostname_suffix:.*|sc_deployment_hostname_suffix: \"{{ meta.namespace }}.${INFRA_NAME}\"|g" ${CP4A_PATTERN_FILE_TMP}
    else
        ${SED_COMMAND} "s|sc_deployment_hostname_suffix:.*|sc_deployment_hostname_suffix: \"{{ meta.namespace }}\"|g" ${CP4A_PATTERN_FILE_TMP}
    fi

    # Set lc_selected_ldap_type

    if [[ $DEPLOYMENT_TYPE == "enterprise" ]];then
        if [[ $LDAP_TYPE == "AD" ]];then
            # ${YQ_CMD} w -i ${CP4A_PATTERN_FILE_TMP} spec.ldap_configuration.lc_selected_ldap_type "\"Microsoft Active Directory\""
            ${SED_COMMAND} "s|lc_selected_ldap_type:.*|lc_selected_ldap_type: \"Microsoft Active Directory\"|g" ${CP4A_PATTERN_FILE_TMP}

        elif [[ $LDAP_TYPE == "TDS" ]]
        then
            # ${YQ_CMD} w -i ${CP4A_PATTERN_FILE_TMP} spec.ldap_configuration.lc_selected_ldap_type "IBM Security Directory Server"
            ${SED_COMMAND} "s|lc_selected_ldap_type:.*|lc_selected_ldap_type: \"IBM Security Directory Server\"|g" ${CP4A_PATTERN_FILE_TMP}
        fi
    fi
    # Set sc_dynamic_storage_classname
    if [[ "$PLATFORM_SELECTED" == "ROKS" ]]; then
        ${SED_COMMAND} "s|sc_dynamic_storage_classname:.*|sc_dynamic_storage_classname: ${FAST_STORAGE_CLASS_NAME}|g" ${CP4A_PATTERN_FILE_TMP}
    else
        ${SED_COMMAND} "s|sc_dynamic_storage_classname:.*|sc_dynamic_storage_classname: ${STORAGE_CLASS_NAME}|g" ${CP4A_PATTERN_FILE_TMP}
    fi
    ${SED_COMMAND} "s|sc_slow_file_storage_classname:.*|sc_slow_file_storage_classname: ${SLOW_STORAGE_CLASS_NAME}|g" ${CP4A_PATTERN_FILE_TMP}
    ${SED_COMMAND} "s|sc_medium_file_storage_classname:.*|sc_medium_file_storage_classname: ${MEDIUM_STORAGE_CLASS_NAME}|g" ${CP4A_PATTERN_FILE_TMP}
    ${SED_COMMAND} "s|sc_fast_file_storage_classname:.*|sc_fast_file_storage_classname: ${FAST_STORAGE_CLASS_NAME}|g" ${CP4A_PATTERN_FILE_TMP}
    # Set image_pull_secrets
    # ${SED_COMMAND} "s|image-pull-secret|$DOCKER_RES_SECRET_NAME|g" ${CP4A_PATTERN_FILE_TMP}
    ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.shared_configuration.image_pull_secrets
    ${YQ_CMD} w -i ${CP4A_PATTERN_FILE_TMP} spec.shared_configuration.image_pull_secrets.[0] "$DOCKER_RES_SECRET_NAME"

    # set sc_image_repository
    if [ "$use_entitlement" = "yes" ] ; then
        ${SED_COMMAND} "s|sc_image_repository:.*|sc_image_repository: ${DOCKER_REG_SERVER}|g" ${CP4A_PATTERN_FILE_TMP}
    else
        ${SED_COMMAND} "s|sc_image_repository:.*|sc_image_repository: ${CONVERT_LOCAL_REGISTRY_SERVER}|g" ${CP4A_PATTERN_FILE_TMP}
    fi

    # Replace image URL
    old_fmcn="$REGISTRY_IN_FILE\/cp\/cp4a\/fncm"
    old_ban="$REGISTRY_IN_FILE\/cp\/cp4a\/ban"
    old_ums="$REGISTRY_IN_FILE\/cp\/cp4a\/ums"
    old_bas="$REGISTRY_IN_FILE\/cp\/cp4a\/bas"
    old_aae="$REGISTRY_IN_FILE\/cp\/cp4a\/aae"
    old_baca="$REGISTRY_IN_FILE\/cp\/cp4a\/baca"
    old_odm="$REGISTRY_IN_FILE\/cp\/cp4a\/odm"
    old_baw="$REGISTRY_IN_FILE\/cp\/cp4a\/baw"
    old_iaws="$REGISTRY_IN_FILE\/cp\/cp4a\/iaws"
    old_ads="$REGISTRY_IN_FILE\/cp\/cp4a\/ads"
    old_bai="$REGISTRY_IN_FILE\/cp\/cp4a"
    old_workflow="$REGISTRY_IN_FILE\/cp\/cp4a\/workflow"
    old_demo="$REGISTRY_IN_FILE\/cp\/cp4a\/demo"
    old_adp="$REGISTRY_IN_FILE\/cp\/cp4a\/iadp"
    old_ier="$REGISTRY_IN_FILE\/cp\/cp4a\/ier"
    old_iccsap="$REGISTRY_IN_FILE\/cp\/cp4a\/iccsap"

    if [ "$use_entitlement" = "yes" ] ; then
        ${SED_COMMAND} "s/$REGISTRY_IN_FILE/$DOCKER_REG_SERVER/g" ${CP4A_PATTERN_FILE_TMP}
    else
        ${SED_COMMAND} "s/$old_db2/$CONVERT_LOCAL_REGISTRY_SERVER/g" ${CP4A_PATTERN_FILE_TMP}
        ${SED_COMMAND} "s/$old_db2_alpine/$CONVERT_LOCAL_REGISTRY_SERVER\/alpine/g" ${CP4A_PATTERN_FILE_TMP}
        ${SED_COMMAND} "s/$old_ldap/$CONVERT_LOCAL_REGISTRY_SERVER/g" ${CP4A_PATTERN_FILE_TMP}
        ${SED_COMMAND} "s/$old_db2_etcd/$CONVERT_LOCAL_REGISTRY_SERVER/g" ${CP4A_PATTERN_FILE_TMP}
        ${SED_COMMAND} "s/$old_busybox/$CONVERT_LOCAL_REGISTRY_SERVER/g" ${CP4A_PATTERN_FILE_TMP}
        ${SED_COMMAND} "s/$old_demo/$CONVERT_LOCAL_REGISTRY_SERVER/g" ${CP4A_PATTERN_FILE_TMP}
        ${SED_COMMAND} "s/$old_fmcn/$CONVERT_LOCAL_REGISTRY_SERVER/g" ${CP4A_PATTERN_FILE_TMP}
        ${SED_COMMAND} "s/$old_ban/$CONVERT_LOCAL_REGISTRY_SERVER/g" ${CP4A_PATTERN_FILE_TMP}
        ${SED_COMMAND} "s/$old_ums/$CONVERT_LOCAL_REGISTRY_SERVER/g" ${CP4A_PATTERN_FILE_TMP}
        ${SED_COMMAND} "s/$old_bas/$CONVERT_LOCAL_REGISTRY_SERVER/g" ${CP4A_PATTERN_FILE_TMP}
        ${SED_COMMAND} "s/$old_aae/$CONVERT_LOCAL_REGISTRY_SERVER/g" ${CP4A_PATTERN_FILE_TMP}
        ${SED_COMMAND} "s/$old_baca/$CONVERT_LOCAL_REGISTRY_SERVER/g" ${CP4A_PATTERN_FILE_TMP}
        ${SED_COMMAND} "s/$old_odm/$CONVERT_LOCAL_REGISTRY_SERVER/g" ${CP4A_PATTERN_FILE_TMP}
        ${SED_COMMAND} "s/$old_baw/$CONVERT_LOCAL_REGISTRY_SERVER/g" ${CP4A_PATTERN_FILE_TMP}
        ${SED_COMMAND} "s/$old_iaws/$CONVERT_LOCAL_REGISTRY_SERVER/g" ${CP4A_PATTERN_FILE_TMP}
        ${SED_COMMAND} "s/$old_ads/$CONVERT_LOCAL_REGISTRY_SERVER/g" ${CP4A_PATTERN_FILE_TMP}
        ${SED_COMMAND} "s/$old_workflow/$CONVERT_LOCAL_REGISTRY_SERVER/g" ${CP4A_PATTERN_FILE_TMP}
        ${SED_COMMAND} "s/$old_adp/$CONVERT_LOCAL_REGISTRY_SERVER/g" ${CP4A_PATTERN_FILE_TMP}
        ${SED_COMMAND} "s/$old_ier/$CONVERT_LOCAL_REGISTRY_SERVER/g" ${CP4A_PATTERN_FILE_TMP}
        ${SED_COMMAND} "s/$old_iccsap/$CONVERT_LOCAL_REGISTRY_SERVER/g" ${CP4A_PATTERN_FILE_TMP}
        ${SED_COMMAND} "/imageCredentials:/{n;s/registry:.*/registry: "${CONVERT_LOCAL_REGISTRY_SERVER}"/;}" ${CP4A_PATTERN_FILE_TMP}

    fi

    # If BAI is selected as an optional component in a demo deployment, the installation of IBM Event Streams
    # 10.0.0+ in the namespace targeted by the ICP4A deployment is a prerequisite. The connection
    # information for Kafka clients is automatically extracted from the Event Streams instance
    # and stored in shared_configuration.kafka_configuration.

    if [[ $DEPLOYMENT_TYPE == "demo" || $DEPLOYMENT_TYPE == "enterprise" ]];then
        containsElement "BusinessAutomationInsights" "${OPT_COMPONENTS_SELECTED[@]}"
        retVal=$?
        if [[ $retVal -eq 0 ]]; then
            printf "\n"
            while true; do
                if [[ $DEPLOYMENT_TYPE == "demo" ]];then
                  printf "\x1B[1mIBM Event Streams installed in the same namespace is a prerequisite for Business Automation Insights when using the deployment script for evaluation purposes. For full capabilities including processing of Avro events, use Event Streams with Apicurio schema registry. Has Event Streams already been deployed to the same namespace for CP4A?\x1B[0m"
                  printf "\n"
                  printf "\x1B[1mFor more information about the IBM Event Streams supported version number and licensing restrictions, see IBM Knowledge Center\x1B[0m"
                  read -rp "?(Yes/No):" ans
                else
                  printf "\x1B[1mIBM Event Streams or another Kafka server is a prerequisite for Business Automation Insights. For full capabilities including processing of Avro events, use Event Streams with Apicurio schema registry. Has IBM Event Streams already been deployed to the same namespace for CP4A? (\x1B[0m"
                  read -rp "?(Yes/No):" ans
                fi
                case "$ans" in
                "y"|"Y"|"yes"|"Yes"|"YES")
                    ${CUR_DIR}/pull-eventstreams-connection-info.sh -f ${CP4A_PATTERN_FILE_TMP} || true
                    retVal=$?
                    if [ $retVal -eq 0 ]; then
                        break
                    else
                        echo -e "\x1B[1;31mThere seems to be an issue with your Event Stream installation, like the Event Stream user might not be ready.\n\x1B[0m"
                        echo -e "\x1B[1;31mPlease check your Event Stream installation and try again.\n\x1B[0m"                      
                        if [[ "$SCRIPT_MODE" == "review" ]]; then
                            echo -e "Continue to deploy ICP4A operator and generate Custom Resource file in \"Review Mode\"...\n"
                            break
                        else
                            echo -e "Exiting...\n"  
                            exit 1
                        fi
                    fi
                    ;;
                "n"|"N"|"no"|"No"|"NO")
                    if [[ $DEPLOYMENT_TYPE == "demo" ]];then
                      printf "\n"
                      printf "\x1B[1mIBM Event Streams installed in the same namespace is a prerequisite for Business Automation Insights when using the deployment script for evaluation purposes. For full capabilities including processing of Avro events, use Event Streams with Apicurio schema registry.\x1B[0m"
                      printf "\n"
                      echo -e "Exiting the deployment. Please ensure that you have Event Streams installed in the same namespace...\n"
                      exit 0
                    else
                      echo -e "\x1B[1;31mYou must manually execute the pull-eventstreams-connection-info.sh script to pull Event Streams configuration information from a different namespace, or manually provide the Kafka connection information in the CP4A custom resource. For details, refer to the documentation in Knowledge Center.\n\x1B[0m"
                      break
                    fi
                    ;;
                *)
                    echo -e "Answer must be \"Yes\" or \"No\"\n"
                    ;;
                esac
            done
        fi
    fi

    object_array=("DEVOS1" "AEOS" "BAWINS1DOCS" "BAWINS1DOS" "BAWINS1TOS" "BAWDOCS" "BAWDOS" "BAWTOS" "AWSINS1DOCS")
    for object_name in "${object_array[@]}"
    do
        containsObjectStore "$object_name" "${CP4A_PATTERN_FILE_TMP}"
        if (( ${#os_index_array[@]} > 1 ));then
            ((index_array_temp=${#os_index_array[@]}-1))
            for ((j=0;j<${index_array_temp};j++))
            do 
                index_os=${os_index_array[$j]}
                ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.datasource_configuration.dc_os_datasources.[$index_os]
            done
        fi
        containsInitObjectStore "$object_name" "${CP4A_PATTERN_FILE_TMP}"
        if (( ${#os_index_array[@]} > 1 ));then
            ((index_array_temp=${#os_index_array[@]}-1))
            for ((j=0;j<${index_array_temp};j++)) 
            do 
                index_os=${os_index_array[$j]}
                ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.initialize_configuration.ic_obj_store_creation.object_stores.[$index_os]
            done
        fi
    done

    containsInitLDAPGroups "${CP4A_PATTERN_FILE_TMP}"
    if (( ${#ldap_groups_index_array[@]} > 1 ));then
        ((index_array_temp=${#ldap_groups_index_array[@]}-1))
        for ((j=0;j<${index_array_temp};j++))
        do 
            index_os=${ldap_groups_index_array[$j]}
            ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.initialize_configuration.ic_ldap_creation.ic_ldap_admins_groups_name.[$index_os]
        done

    fi

    containsInitLDAPUsers "${CP4A_PATTERN_FILE_TMP}"
     if (( ${#ldap_users_index_array[@]} > 1 ));then
        ((index_array_temp=${#ldap_users_index_array[@]}-1))
        for ((j=0;j<${index_array_temp};j++))
        do 
            index_os=${ldap_users_index_array[$j]}
            ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.initialize_configuration.ic_ldap_creation.ic_ldap_admin_user_name.[$index_os]
        done
        
    fi

    baw_name_array=("bawins1" "awsins1")
    for object_name in "${baw_name_array[@]}"
    do
        containsBAWInstance "$object_name" "${CP4A_PATTERN_FILE_TMP}"
        if (( ${#baw_index_array[@]} > 1 ));then
            ((index_array_temp=${#baw_index_array[@]}-1))
            for ((j=0;j<${index_array_temp};j++))
            do 
                index_os=${baw_index_array[$j]}
                ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.baw_configuration.[$index_os]
            done
        fi
    done

    containsAEInstance "${CP4A_PATTERN_FILE_TMP}"
     if (( ${#ae_index_array[@]} > 1 ));then
        ((index_array_temp=${#ae_index_array[@]}-1))
        for ((j=0;j<${index_array_temp};j++))
        do 
            index_os=${ae_index_array[$j]}
            ${YQ_CMD} d -i ${CP4A_PATTERN_FILE_TMP} spec.application_engine_configuration.[$index_os]
        done
        
    fi 

    ${COPY_CMD} -rf ${CP4A_PATTERN_FILE_TMP} ${CP4A_PATTERN_FILE_BAK}
    echo -e "\x1B[1mThe custom resource file used is: \"${CP4A_PATTERN_FILE_BAK}\"\x1B[0m"

    printf "\n"
    echo -e "\x1B[1mTo monitor the deployment status, follow the Operator logs.\x1B[0m"
    echo -e "\x1B[1mFor details, refer to the troubleshooting section in Knowledge Center here: \x1B[0m"
    echo -e "\x1B[1mhttps://www.ibm.com/support/knowledgecenter/SSYHZ8_20.0.x/com.ibm.dba.install/op_topics/tsk_trbleshoot_operators.html\x1B[0m"
}
# End - Modify FOUNDATION pattern yaml according pattent/components selected

function prepare_pattern_file(){
    ${COPY_CMD} -rf "${OPERATOR_FILE}" "${OPERATOR_FILE_BAK}"
    ${COPY_CMD} -rf "${OPERATOR_PVC_FILE}" "${OPERATOR_PVC_FILE_BAK}"

    if [[ "$DEPLOYMENT_TYPE" == "enterprise" ]];then
        DEPLOY_TYPE_IN_FILE_NAME="enterprise"
    else
        DEPLOY_TYPE_IN_FILE_NAME="demo"
    fi

    FOUNDATION_PATTERN_FILE=${PARENT_DIR}/install/cert-kubernetes/descriptors/patterns/ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_foundation.yaml


    CONTENT_PATTERN_FILE=${PARENT_DIR}/install/cert-kubernetes/descriptors/patterns/ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_content.yaml
    CONTENT_PATTERN_FILE_TMP=$TEMP_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_content_tmp.yaml
    CONTENT_PATTERN_FILE_BAK=$BAK_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_content.yaml

    APPLICATION_PATTERN_FILE=${PARENT_DIR}/install/cert-kubernetes/descriptors/patterns/ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_application.yaml
    APPLICATION_PATTERN_FILE_TMP=$TEMP_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_application_tmp.yaml
    APPLICATION_PATTERN_FILE_BAK=$BAK_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_application.yaml

    DECISIONS_PATTERN_FILE=${PARENT_DIR}/install/cert-kubernetes/descriptors/patterns/ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_decisions.yaml
    DECISIONS_PATTERN_FILE_TMP=$TEMP_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_decisions_tmp.yaml
    DECISIONS_PATTERN_FILE_BAK=$BAK_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_decisions.yaml

    ADS_PATTERN_FILE=${PARENT_DIR}/install/cert-kubernetes/descriptors/patterns/ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_decisions_ads.yaml
    ADS_PATTERN_FILE_TMP=$TEMP_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_decisions_ads_tmp.yaml
    ADS_PATTERN_FILE_BAK=$BAK_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_decisions_ads.yaml

    ARIA_PATTERN_FILE=${PARENT_DIR}/install/cert-kubernetes/descriptors/patterns/ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_document_processing.yaml
    ARIA_PATTERN_FILE_TMP=$TEMP_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_document_processing_tmp.yaml
    ARIA_PATTERN_FILE_BAK=$BAK_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_document_processing.yaml

    ${COPY_CMD} -rf "${CONTENT_PATTERN_FILE}" "${CONTENT_PATTERN_FILE_BAK}"
    ${COPY_CMD} -rf "${APPLICATION_PATTERN_FILE}" "${APPLICATION_PATTERN_FILE_BAK}"
    ${COPY_CMD} -rf "${ADS_PATTERN_FILE}" "${ADS_PATTERN_FILE_BAK}"
    ${COPY_CMD} -rf "${DECISIONS_PATTERN_FILE}" "${DECISIONS_PATTERN_FILE_BAK}"
    ${COPY_CMD} -rf "${ARIA_PATTERN_FILE}" "${ARIA_PATTERN_FILE_BAK}"
    # ${COPY_CMD} -rf "${ACA_PATTERN_FILE}" "${ACA_PATTERN_FILE_BAK}"
    # ${COPY_CMD} -rf "${ADW_PATTERN_FILE}" "${ADW_PATTERN_FILE_BAK}"
    # support existing installation
    # if [ -f "$CP4A_PATTERN_FILE_BAK" ]; then
    #     ${COPY_CMD} -rf "${CP4A_PATTERN_FILE_BAK}" "${CP4A_EXISTING_BAK}"
    #     ${YQ_CMD} d -i ${CP4A_EXISTING_BAK} spec.shared_configuration
    # else
    #     ${COPY_CMD} -rf "${FOUNDATION_PATTERN_FILE}" "${CP4A_PATTERN_FILE_BAK}"
    # fi
    ${COPY_CMD} -rf "${FOUNDATION_PATTERN_FILE}" "${CP4A_PATTERN_FILE_TMP}"
    if [[ "$DEPLOYMENT_TYPE" == "demo" ]];then
        # WORKFLOW_PATTERN_FILE=${PARENT_DIR}/install/cert-kubernetes/descriptors/patterns/ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow.yaml
        # WORKFLOW_PATTERN_FILE_TMP=$TEMP_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow_tmp.yaml
        # WORKFLOW_PATTERN_FILE_BAK=$BAK_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow.yaml

        # WORKSTREAMS_PATTERN_FILE=${PARENT_DIR}/install/cert-kubernetes/descriptors/patterns/ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workstreams.yaml
        # WORKSTREAMS_PATTERN_FILE_TMP=$TEMP_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workstreams_tmp.yaml
        # WORKSTREAMS_PATTERN_FILE_BAK=$BAK_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workstreams.yaml

        WW_PATTERN_FILE=${PARENT_DIR}/install/cert-kubernetes/descriptors/patterns/ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow_authoring-workstreams.yaml
        WW_PATTERN_FILE_TMP=$TEMP_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow-workstreams_tmp.yaml
        WW_PATTERN_FILE_BAK=$BAK_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow_authoring-workstreams.yaml
        # ${COPY_CMD} -rf "${WORKFLOW_PATTERN_FILE}" "${WORKFLOW_PATTERN_FILE_BAK}"
        ${COPY_CMD} -rf "${WW_PATTERN_FILE}" "${WW_PATTERN_FILE_BAK}"
        # get_baw_mode
        # retVal_baw=$?
        # if [ $retVal_baw -eq 0 ]; then
        #     WORKFLOW_PATTERN_FILE=${PARENT_DIR}/install/cert-kubernetes/descriptors/patterns/ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow.yaml
        #     WORKFLOW_PATTERN_FILE_TMP=$TEMP_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow_tmp.yaml
        #     WORKFLOW_PATTERN_FILE_BAK=$BAK_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow.yaml
        # else
        #     WORKFLOW_PATTERN_FILE=${PARENT_DIR}/install/cert-kubernetes/descriptors/patterns/ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow_authoring-workstreams.yaml
        #     WORKFLOW_PATTERN_FILE_TMP=$TEMP_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow-workstreams_tmp.yaml
        #     WORKFLOW_PATTERN_FILE_BAK=$BAK_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow_authoring-workstreams.yaml
        # fi
    elif [[ "$DEPLOYMENT_TYPE" == "enterprise" ]]
    then
        WORKFLOW_PATTERN_FILE=${PARENT_DIR}/install/cert-kubernetes/descriptors/patterns/ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow.yaml
        WORKFLOW_PATTERN_FILE_TMP=$TEMP_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow_tmp.yaml
        WORKFLOW_PATTERN_FILE_BAK=$BAK_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow.yaml

        WORKSTREAMS_PATTERN_FILE=${PARENT_DIR}/install/cert-kubernetes/descriptors/patterns/ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workstreams.yaml
        WORKSTREAMS_PATTERN_FILE_TMP=$TEMP_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workstreams_tmp.yaml
        WORKSTREAMS_PATTERN_FILE_BAK=$BAK_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workstreams.yaml

        WORKFLOW_AUTHOR_PATTERN_FILE=${PARENT_DIR}/install/cert-kubernetes/descriptors/patterns/ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow_authoring.yaml
        WORKFLOW_AUTHOR_PATTERN_FILE_TMP=$TEMP_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow_authoring_tmp.yaml
        WORKFLOW_AUTHOR_PATTERN_FILE_BAK=$BAK_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow_authoring.yaml

        # merge workflow with workstreams templat for workflow-workstreams in 4Q
        ${YQ_CMD} m -a -M ${WORKFLOW_PATTERN_FILE} ${WORKSTREAMS_PATTERN_FILE} > /tmp/ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow_workstreams.yaml
        WW_PATTERN_FILE=/tmp/ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow_workstreams.yaml
        ${YQ_CMD} d -i ${WW_PATTERN_FILE} spec.initialize_configuration.ic_obj_store_creation.object_stores.[3]
        ${YQ_CMD} d -i ${WW_PATTERN_FILE} spec.datasource_configuration.dc_os_datasources.[3]
        ${YQ_CMD} d -i ${WW_PATTERN_FILE} spec.initialize_configuration.ic_ldap_creation.ic_ldap_admin_user_name.[1]
        ${YQ_CMD} d -i ${WW_PATTERN_FILE} spec.initialize_configuration.ic_ldap_creation.ic_ldap_admins_groups_name.[1]
        ${YQ_CMD} w -i ${WW_PATTERN_FILE} spec.baw_configuration.[0].host_federated_portal false
        ${YQ_CMD} w -i ${WW_PATTERN_FILE} spec.baw_configuration.[1].host_federated_portal false
        ${YQ_CMD} w -i ${WW_PATTERN_FILE} spec.baw_configuration.[0].host_federated_portal true
        WW_PATTERN_FILE_TMP=$TEMP_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow_workstreams_tmp.yaml
        WW_PATTERN_FILE_BAK=$BAK_FOLDER/.ibm_cp4a_cr_${DEPLOY_TYPE_IN_FILE_NAME}_workflow_workstreams.yaml

        ${COPY_CMD} -rf "${WORKFLOW_PATTERN_FILE}" "${WORKFLOW_PATTERN_FILE_BAK}"
        ${COPY_CMD} -rf "${WORKSTREAMS_PATTERN_FILE}" "${WORKSTREAMS_PATTERN_FILE_BAK}"
        ${COPY_CMD} -rf "${WORKFLOW_AUTHOR_PATTERN_FILE}" "${WORKFLOW_AUTHOR_PATTERN_FILE_BAK}"
        ${COPY_CMD} -rf "${WW_PATTERN_FILE}" "${WW_PATTERN_FILE_BAK}"
    fi
}
################################################
#### Begin - Main step for install operator ####
################################################
IBM_LICENS="Accept"
input_information
apply_pattern_cr
################################################
#### End - Main step for install operator ####
################################################
