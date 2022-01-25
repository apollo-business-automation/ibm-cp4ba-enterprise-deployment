#!/usr/bin/env bash

##
## Licensed Materials - Property of IBM
## 5737-I23
## Copyright IBM Corp. 2018 - 2021. All Rights Reserved.
## U.S. Government Users Restricted Rights:
## Use, duplication or disclosure restricted by GSA ADP Schedule
## Contract with IBM Corp.
##

. ./ScriptFunctions.sh

INPUT_PROPS_FILENAME="./common_for_DB2_Upgrade.sh"

if [ -f $INPUT_PROPS_FILENAME ]; then
   echo "Found a $INPUT_PROPS_FILENAME.  Reading in variables from that script."
   . $INPUT_PROPS_FILENAME
fi

echo -e "\n-- This script will upgrade base DB"
echo

while [[ $base_db_name == '' ]]
do
  echo "Please enter a valid value for the base database name :"
  read base_db_name
  while [ ${#base_db_name} -gt 8 ];
  do
    echo "Please enter a valid value for the base database name :"
    read base_db_name;
    echo ${#base_db_name};
  done
done

while [[ -z "$base_db_user" ||  $base_db_user == "" ]]
do
  echo "Please enter a valid value for the base database user name :"
  read base_db_user
done

echo
echo "-- Please confirm these are the desired settings:"
echo " - Base database name: $base_db_name"
echo " - Base database user name: $base_db_user"
askForConfirmation


cp sql/UpgradeBaseDB_21.0.2_to_21.0.3.sql.template sql/UpgradeBaseDB_21.0.2_to_21.0.3.sql
sed -i s/\$base_db_name/"$base_db_name"/ sql/UpgradeBaseDB_21.0.2_to_21.0.3.sql
sed -i s/\$base_db_user/"$base_db_user"/ sql/UpgradeBaseDB_21.0.2_to_21.0.3.sql
echo
echo "Running upgrade script: sql/UpgradeBaseDB_21.0.2_to_21.0.3.sql"
db2 -stvf sql/UpgradeBaseDB_21.0.2_to_21.0.3.sql