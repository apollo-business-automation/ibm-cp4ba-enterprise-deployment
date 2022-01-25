#!/bin/bash
##
## Licensed Materials - Property of IBM
## 5737-I23
## Copyright IBM Corp. 2018 - 2021. All Rights Reserved.
## U.S. Government Users Restricted Rights:
## Use, duplication or disclosure restricted by GSA ADP Schedule
## Contract with IBM Corp.
##

. ./ScriptFunctions.sh

echo
echo "---------------------------------------------------------------------------------------"
echo -e "\n This script will delete all ADP project databases that are marked for deletion. \n"
echo "---------------------------------------------------------------------------------------"

askForConfirmation

echo 
echo "This script will query the ACA Base database to determine which databases (if any) are marked for deletion..."
echo
default_basedb='BASECA'
if [[ -z "$base_db_name" ]]; then
  echo -e "\nEnter the name of the ACA Base database with the TENANTINFO Table. If nothing is entered, we will use the following default value : " $default_basedb
  read base_db_name
  if [[ -z "$base_db_name" ]]; then
     base_db_name=$default_basedb
  fi
fi

default_basedb_user='CABASEUSER'
if [[ -z "$base_db_user" ]]; then
  echo -e "\nEnter the name of the database user for the ACA Base database. If nothing is entered, we will use the following default value : " $default_basedb_user
  read base_db_user
  if [[ -z "$base_db_user" ]]; then
     base_db_user=$default_basedb_user 
  fi
fi

function delete_tenant(){
    tenant_db=$3
    base_db_name=$1
    base_db_user=$2
    tenant_user=$4
    tenant_id=$5
    db2 "connect to $tenant_db"
    resp=$(db2 -x "QUIESCE DATABASE IMMEDIATE FORCE CONNECTIONS")
    rc=$(echo  $resp | awk '{print $1}')

    if [[ "$rc" == "DB20000I" || "$rc" == "SQL1371W" ]]
    then
        echo "DB Quiesced"
        db2 "unquiesce database"
        db2 "connect reset"
        resp=$(db2 -x "drop db $tenant_db")
        rc=$(echo  $resp | awk '{print $1}')
        if [[ "$rc" == "DB20000I" ]]
        then
            echo "DB Dropped"
            db2 "connect to $base_db_name"
            db2 "set schema $base_db_user"
            db2 "delete from tenantinfo where dbname='$tenant_db'"
            echo "Deleted the project database with tenant ID: " $tenant_id ", database name: " $tenant_db
            echo
        else
            echo "Failed to drop the database: " $rc
        fi
    else 
        echo "Quiesce failed: " $rc
    fi 
}


SaveIFS="$IFS"
IFS=$'\n'
db2 "connect to $base_db_name"
db2 "set schema $base_db_user"
array=($(db2 -x "select dbname,dbuser,tenantid,project_guid from tenantinfo where dbstatus=2"))
END=${#array[@]}
for j in $(seq 0 $(($END-1)))
do
  echo -e "\nIMPORTANT: The following project databases will be deleted.  Please verify this is what you want: "
  tenant_db=$(echo ${array[i]} | awk '{print $1}')
  tenant_id=$(echo ${array[i]} | awk '{print $3}')
  project_guid=$(echo ${array[i]} | awk '{print $4}')
  echo "- Project ID: " $project_guid " , tenant ID: " $tenant_id ", database name: " $tenant_db
done
echo -e "\nTotal projects found that are marked for deletion: "$END

if [[ "$END" != "0" ]]; then
  unset confirmation
  askForConfirmation
fi

IFS="$SaveIFS"
for i in $(seq 0 $(($END-1)))
do
  db2 "connect reset"
  tenant_db=$(echo ${array[i]} | awk '{print $1}')
  tenant_user=$(echo ${array[i]} | awk '{print $2}')
  tenant_id=$(echo ${array[i]} | awk '{print $3}')
  project_guid=$(echo ${array[i]} | awk '{print $4}')
  echo
  echo "- Deleting the project database with project ID: " $project_guid " , tenant ID: " $tenant_id ", database name: " $tenant_db
  db2 "deactivate db $tenant_db"
  delete_tenant $base_db_name $base_db_user $tenant_db $tenant_user $tenant_id $project_guid
done
