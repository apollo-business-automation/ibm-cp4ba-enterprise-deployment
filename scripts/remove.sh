#!/bin/bash

echo
echo ">>>>Source internal variables"
. internal-variables.sh

echo
echo ">>>>Source variables"
. variables.sh

echo
echo ">>>>Source functions"
. functions.sh

echo
echo ">>>>$(print_timestamp) CP4BA Enterprise remove started"

echo
echo ">>>>Init env"
. init.sh

if [[ $RPA_ENABLED == "true" ]]; then
echo
echo ">>>>$(print_timestamp) Remove RPA"
cd rpa
./remove.sh
exit_test $? "Remove RPA Failed"
cd ..

echo
echo ">>>>$(print_timestamp) Remove MSSQL"
cd mssql
./remove.sh
exit_test $? "Remove MSSQL Failed"
cd ..
fi

if [[ $ASSET_REPO_ENABLED == "true" ]]; then
echo
echo ">>>>$(print_timestamp) Remove Asset Repo"
cd asset-repo
./remove.sh
exit_test $? "Remove Asset Repo Failed"
cd ..
fi

if [[ $PM_ENABLED == "true" ]]; then
echo
echo ">>>>$(print_timestamp) Remove PM"
cd pm
./remove.sh
exit_test $? "Remove PM Failed"
cd ..
fi

echo
echo ">>>>$(print_timestamp) Remove CP4BA"
cd cp4ba
./remove.sh
exit_test $? "Remove CP4BA Failed"
cd ..

echo
echo ">>>>$(print_timestamp) Remove CPFS"
cd cpfs
./remove.sh
exit_test $? "Remove CPFS Failed"
cd ..

echo
echo ">>>>$(print_timestamp) Remove Kibana"
cd kibana
./remove.sh
exit_test $? "Remove Kibana Failed"
cd ..

if [[ $AKHQ_ENABLED == "true" ]]; then
echo
echo ">>>>$(print_timestamp) Remove AKHQ"
cd akhq
./remove.sh
exit_test $? "Remove AKHQ Failed"
cd ..
fi

if [[ $CEREBRO_ENABLED == "true" ]]; then
echo
echo ">>>>$(print_timestamp) Remove Cerebro"
cd cerebro
./remove.sh
exit_test $? "Remove Cerebro Failed"
cd ..
fi

if [[ $ROUNDCUBE_ENABLED == "true" ]]; then
echo
echo ">>>>$(print_timestamp) Remove Roundcube"
cd roundcube
./remove.sh
exit_test $? "Remove Roundcube Failed"
cd ..
fi

echo
echo ">>>>$(print_timestamp) Remove Mail"
cd mail
./remove.sh
exit_test $? "Remove Mail Failed"
cd ..

echo
echo ">>>>$(print_timestamp) Remove Nexus"
cd nexus
./remove.sh
exit_test $? "Remove Nexus Failed"
cd ..

echo
echo ">>>>$(print_timestamp) Remove Gitea"
cd gitea
./remove.sh
exit_test $? "Remove Gitea Failed"
cd ..

echo
echo ">>>>$(print_timestamp) Remove OpenLDAP + phpLDAPadmin"
cd openldap
./remove.sh
exit_test $? "Remove OpenLDAP + phpLDAPadmin Failed"
cd ..

if [[ $DB2MC_ENABLED == "true" ]]; then
echo
echo ">>>>$(print_timestamp) Remove DB2MC"
cd db2mc
./remove.sh
exit_test $? "Remove DB2MC Failed"
cd ..
fi

echo
echo ">>>>$(print_timestamp) Remove DB2"
cd db2
./remove.sh
exit_test $? "Remove DB2 Failed"
cd ..

echo
echo ">>>>$(print_timestamp) Remove Common"
cd common
./remove.sh
exit_test $? "Remove Common Failed"
cd ..

echo
echo ">>>>$(print_timestamp) Remove Global CA"
cd global-ca
./remove.sh
exit_test $? "Remove Global CA Failed"
cd ..

echo
echo ">>>>$(print_timestamp) CP4BA Enterprise remove completed"
