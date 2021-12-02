#!/bin/bash

echo
echo ">>>>Source internal variables"
. inernal-variables.sh

echo
echo ">>>>Source variables"
. variables.sh

echo
echo ">>>>Source functions"
. functions.sh

echo
echo ">>>>$(print_timestamp) $(print_timestamp) CP4BA Enterprise install started"

echo
echo ">>>>Init env"
. init.sh

echo
echo ">>>>$(print_timestamp) Generate Usage documentation"
sed -i "s|{{OCP_APPS_ENDPOINT}}|${OCP_APPS_ENDPOINT}|g" usage.md
sed -i "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" usage.md
sed -i "s|{{UNIVERSAL_PASSWORD}}|${ESCAPED_UNIVERSAL_PASSWORD}|g" usage.md

if [[ $CONTAINER_RUN_MODE == "true" ]]; then
  oc project automagic
  oc create cm usage --from-file=usage.md=usage.md -o yaml --dry-run=client | oc apply -f -
fi

echo
echo ">>>>$(print_timestamp) Install Global CA"
cd global-ca
./install.sh
exit_test $? "Install Global CA Failed"
cd ..

echo
echo ">>>>$(print_timestamp) Install Common"
cd common
./install.sh
exit_test $? "Install Common Failed"
cd ..

echo
echo ">>>>$(print_timestamp) Install DB2"
cd db2
./install.sh
exit_test $? "Install DB2 Failed"
cd ..

if [[ $DB2MC_ENABLED == "true" ]]; then
echo
echo ">>>>$(print_timestamp) Install DB2MC"
cd db2mc
./install.sh
exit_test $? "Install DB2MC Failed"
cd ..
fi

echo
echo ">>>>$(print_timestamp) Install OpenLDAP + phpLDAPadmin"
cd openldap
./install.sh
exit_test $? "Install OpenLDAP + phpLDAPadmin Failed"
cd ..

echo
echo ">>>>$(print_timestamp) Install Gitea"
cd gitea
./install.sh
exit_test $? "Install Gitea Failed"
cd ..

echo
echo ">>>>$(print_timestamp) Install Nexus"
cd nexus
./install.sh
exit_test $? "Install Nexus Failed"
cd ..

echo
echo ">>>>$(print_timestamp) Install Mail"
cd mail
./install.sh
exit_test $? "Install Mail Failed"
cd ..

if [[ $ROUNDCUBE_ENABLED == "true" ]]; then
echo
echo ">>>>$(print_timestamp) Install Roundcube"
cd roundcube
./install.sh
exit_test $? "Install Roundcube Failed"
cd ..
fi

if [[ $CEREBRO_ENABLED == "true" ]]; then
echo
echo ">>>>$(print_timestamp) Install Cerebro"
cd cerebro
./install.sh
exit_test $? "Install Cerebro Failed"
cd ..
fi

if [[ $AKHQ_ENABLED == "true" ]]; then
echo
echo ">>>>$(print_timestamp) Install AKHQ"
cd akhq
./install.sh
exit_test $? "Install AKHQ Failed"
cd ..
fi

echo
echo ">>>>$(print_timestamp) Install Kibana"
cd kibana
./install.sh
exit_test $? "Install Kibana Failed"
cd ..

echo
echo ">>>>$(print_timestamp) Install CPFS"
cd cpfs
./install.sh
exit_test $? "Install CPFS Failed"
cd ..

echo
echo ">>>>$(print_timestamp) Install CP4BA"
cd cp4ba
./install.sh
exit_test $? "Install CP4BA Failed"
cd ..

if [[ $PM_ENABLED == "true" ]]; then
echo
echo ">>>>$(print_timestamp) Install PM"
cd pm
./install.sh
exit_test $? "Install PM Failed"
cd ..
fi

if [[ $ASSET_REPO_ENABLED == "true" ]]; then
echo
echo ">>>>$(print_timestamp) Install Asset Repo"
cd asset-repo
./install.sh
exit_test $? "Install Asset Repo Failed"
cd ..
fi

if [[ $RPA_ENABLED == "true" ]]; then
echo
echo ">>>>$(print_timestamp) Install MSSQL"
cd mssql
./install.sh
exit_test $? "Install MSSQL Failed"
cd ..

echo
echo ">>>>$(print_timestamp) Install RPA"
cd rpa
./install.sh
exit_test $? "Install RPA Failed"
cd ..
fi

echo
echo ">>>>$(print_timestamp) CP4BA Enterprise install completed"
