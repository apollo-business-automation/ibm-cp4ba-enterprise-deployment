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
echo -e "\n-- This script will re-initialize with default data all existing ADP projects marked for delete."
echo "---------------------------------------------------------------------------------------"

askForConfirmation

default_basedb='BASECA'
if [[ -z "$base_db_name" ]]; then
  echo -e "\nEnter the name of the Base ACA database with the TENANTINFO Table. If nothing is entered, we will use the following default value : " $default_basedb
  read base_db_name
  if [[ -z "$base_db_name" ]]; then
     base_db_name=$default_basedb
  fi
fi

default_basedb_user='CABASEUSER'
if [[ -z "$base_db_user" ]]; then
  echo -e "\nEnter the name of the database user for the Base ACA database. If nothing is entered, we will use the following default value : " $default_basedb_user
  read base_db_user
  if [[ -z "$base_db_user" ]]; then
     base_db_user=$default_basedb_user 
  fi
fi


SaveIFS="$IFS"

IFS=$'\n'
db2 "connect to $base_db_name"
db2 "set schema $base_db_user"
array=($(db2 -x "select dbname,dbuser,tenantid,ontology from tenantinfo where dbstatus=2"))
END=${#array[@]}
echo "Total projects marked for reclaim: "$END
IFS="$SaveIFS"
for i in $(seq 0 $(($END-1)))
do
  db2 "connect reset"
  tenant_db=$(echo ${array[i]} | awk '{print $1}')
  tenant_user=$(echo ${array[i]} | awk '{print $2}')
  tenant_id=$(echo ${array[i]} | awk '{print $3}')
  tenant_ontology=$(echo ${array[i]} | awk '{print $4}')
  echo "Cleaning the project with id: "$tenant_id
  db2 "connect to $tenant_db"
  db2 "set schema $tenant_ontology"
  db2 -stvf sql/DropBacaTables.sql
  echo -e "\nRunning script: sql/CreateBacaTables.sql"
  db2 -tf sql/CreateBacaTables.sql
  cd imports
  db2 -tvf ./importTables.sql
  db2 "connect reset"
  db2 "connect to $base_db_name"
  db2 "set schema $base_db_user"
  db2 "update tenantinfo set dbstatus=0 where tenantid='$tenant_id' and ontology='$tenant_ontology'"
done
