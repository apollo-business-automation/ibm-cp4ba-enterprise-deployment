#!/bin/bash

echo
echo ">>>>Source internal variables"
. ../internal-variables.sh

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) CP4BA DBs install started"

echo
echo ">>>>Init env"
. ../init.sh

echo
echo ">>>>$(print_timestamp) Create DB users"
# Based on https://www.ibm.com/docs/en/db2/11.5?topic=ldap-managing-users
ldap_pod=$(oc get pod -n db2 -o name | grep ldap)
echo
echo ">>>>$(print_timestamp) Create DB user ums"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/addLdapUser.py -u ums -p ${UNIVERSAL_PASSWORD} -r user
echo
echo ">>>>$(print_timestamp) Create DB user umsts"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/addLdapUser.py -u umsts -p ${UNIVERSAL_PASSWORD} -r user
echo
echo ">>>>$(print_timestamp) Create DB user icndb"
# Needs to be ICNDB as container counts on such name internally for schema name
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/addLdapUser.py -u icndb -p ${UNIVERSAL_PASSWORD} -r user
echo
echo ">>>>$(print_timestamp) Create DB user pb"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/addLdapUser.py -u pb -p ${UNIVERSAL_PASSWORD} -r user
echo
echo ">>>>$(print_timestamp) Create DB user bas"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/addLdapUser.py -u bas -p ${UNIVERSAL_PASSWORD} -r user
echo
echo ">>>>$(print_timestamp) Create DB user odm"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/addLdapUser.py -u odm -p ${UNIVERSAL_PASSWORD} -r user
echo
echo ">>>>$(print_timestamp) Create DB user gcd"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/addLdapUser.py -u gcd -p ${UNIVERSAL_PASSWORD} -r user
echo
echo ">>>>$(print_timestamp) Create DB user os1"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/addLdapUser.py -u os1 -p ${UNIVERSAL_PASSWORD} -r user
echo
echo ">>>>$(print_timestamp) Create DB user aae"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/addLdapUser.py -u aae -p ${UNIVERSAL_PASSWORD} -r user
echo
echo ">>>>$(print_timestamp) Create DB user aeos"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/addLdapUser.py -u aeos -p ${UNIVERSAL_PASSWORD} -r user
echo
echo ">>>>$(print_timestamp) Create DB user base"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/addLdapUser.py -u base -p ${UNIVERSAL_PASSWORD} -r user
echo
echo ">>>>$(print_timestamp) Create DB user devos1"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/addLdapUser.py -u devos1 -p ${UNIVERSAL_PASSWORD} -r user
echo
echo ">>>>$(print_timestamp) Create DB user badocs"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/addLdapUser.py -u badocs -p ${UNIVERSAL_PASSWORD} -r user
echo
echo ">>>>$(print_timestamp) Create DB user batos"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/addLdapUser.py -u batos -p ${UNIVERSAL_PASSWORD} -r user
echo
echo ">>>>$(print_timestamp) Create DB user bados"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/addLdapUser.py -u bados -p ${UNIVERSAL_PASSWORD} -r user
echo
echo ">>>>$(print_timestamp) Create DB user bawaut"
oc rsh -n db2 ${ldap_pod} /opt/ibm/ldap_scripts/addLdapUser.py -u bawaut -p ${UNIVERSAL_PASSWORD} -r user

echo
echo ">>>>$(print_timestamp) Create & configure CP4BA DB"
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 create database CP4BA automatic storage yes using codeset UTF-8 territory US pagesize 32768;
db2 activate db CP4BA
db2 CONNECT TO CP4BA
db2 CREATE BUFFERPOOL CP4BA_BP_32K IMMEDIATE SIZE AUTOMATIC PAGESIZE 32K;
db2 DROP TABLESPACE USERSPACE1
EOSSH

echo
echo ">>>>$(print_timestamp) User Management Services (UMS) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-preparing-install-user-management-services

echo
echo ">>>>$(print_timestamp) UMS DB"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=database-preparing-db2
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 CONNECT TO CP4BA;
db2 CREATE REGULAR TABLESPACE UMS_TS PAGESIZE 32 K BUFFERPOOL CP4BA_BP_32K;
db2 CREATE USER TEMPORARY TABLESPACE UMS_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE SYSTEM TEMPORARY TABLESPACE UMS_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;

db2 GRANT DBADM ON DATABASE TO user ums;
db2 GRANT USE OF TABLESPACE UMS_TS TO user ums;
db2 GRANT USE OF TABLESPACE UMS_TEMP_TS TO user ums;
db2 CONNECT RESET;
EOSSH

echo
echo ">>>>$(print_timestamp) UMSTS DB"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=database-preparing-db2
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 CONNECT TO CP4BA;
db2 CREATE REGULAR TABLESPACE UMSTS_TS PAGESIZE 32 K BUFFERPOOL CP4BA_BP_32K;
db2 CREATE USER TEMPORARY TABLESPACE UMSTS_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE SYSTEM TEMPORARY TABLESPACE UMSTS_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;

db2 GRANT DBADM ON DATABASE TO user umsts;
db2 GRANT USE OF TABLESPACE UMSTS_TS TO user umsts;
db2 GRANT USE OF TABLESPACE UMSTS_TEMP_TS TO user umsts;
db2 CONNECT RESET;
EOSSH

echo
echo ">>>>$(print_timestamp) Business Automation Navigator (BAN) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-preparing-install-business-automation-navigator

echo
echo ">>>>$(print_timestamp) BAN DB"
# Based on https://www.ibm.com/docs/en/content-navigator/[BAN_KC_VERSION]?topic=navigator-creating-db2-database-content
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 CONNECT TO CP4BA;
db2 CREATE REGULAR TABLESPACE ICNDB_TS PAGESIZE 32 K BUFFERPOOL CP4BA_BP_32K;
db2 CREATE USER TEMPORARY TABLESPACE ICNDB_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE SYSTEM TEMPORARY TABLESPACE ICNDB_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;

db2 GRANT DBADM ON DATABASE TO user icndb;
db2 GRANT USE OF TABLESPACE ICNDB_TS TO user icndb;
db2 GRANT USE OF TABLESPACE ICNDB_TEMP_TS TO user icndb;
db2 CONNECT RESET;
EOSSH

echo
echo ">>>>$(print_timestamp) Business Automation Studio (BAS) (foundation pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-preparing-install-business-automation-studio

echo
echo ">>>>$(print_timestamp) PB DB"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=studio-creating-databases
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 CONNECT TO CP4BA;
db2 CREATE REGULAR TABLESPACE PB_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE USER TEMPORARY TABLESPACE PB_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE SYSTEM TEMPORARY TABLESPACE PB_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;

db2 GRANT DBADM ON DATABASE TO user pb;
db2 GRANT USE OF TABLESPACE PB_TS TO user pb;
db2 GRANT USE OF TABLESPACE PB_TEMP_TS TO user pb;
db2 CONNECT RESET;
EOSSH

echo
echo ">>>>$(print_timestamp) BAS DB"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=studio-creating-databases
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 CONNECT TO CP4BA;
db2 CREATE REGULAR TABLESPACE BAS_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE USER TEMPORARY TABLESPACE BAS_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE SYSTEM TEMPORARY TABLESPACE BAS_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;

db2 GRANT DBADM ON DATABASE TO user bas;
db2 GRANT USE OF TABLESPACE BAS_TS TO user bas;
db2 GRANT USE OF TABLESPACE BAS_TEMP_TS TO user bas;

db2 UPDATE DB CFG FOR CP4BA USING LOGFILSIZ 16384 DEFERRED; #largest value
db2 UPDATE DB CFG FOR CP4BA USING LOGSECOND 64 IMMEDIATE; #largest value
db2 CONNECT RESET;
EOSSH

echo
echo ">>>>$(print_timestamp) Operational Decision Manager (ODM) (decisions pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-preparing-install-operational-decision-manager

echo
echo ">>>>$(print_timestamp) ODM DB"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=manager-configuring-external-database
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 CONNECT TO CP4BA;
db2 CREATE REGULAR TABLESPACE ODM_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE USER TEMPORARY TABLESPACE ODM_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE SYSTEM TEMPORARY TABLESPACE ODM_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;

db2 GRANT DBADM ON DATABASE TO user odm;
db2 GRANT USE OF TABLESPACE ODM_TS TO user odm;
db2 GRANT USE OF TABLESPACE ODM_TEMP_TS TO user odm;
db2 CONNECT RESET;
EOSSH

echo
echo ">>>>$(print_timestamp) FileNet Content Manager (FNCM) (content pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-preparing-install-filenet-content-manager

echo
echo ">>>>$(print_timestamp) Set DB2_WORKLOAD"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=manager-preparing-databases
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2set DB2_WORKLOAD=FILENET_CM
EOSSH

echo
echo ">>>>$(print_timestamp) GCD DB"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=manager-preparing-databases
# Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=vtdluwiifp-creating-db2-database-table-space-content-platform-engine-gcd
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 CONNECT TO CP4BA;
db2 CREATE LARGE TABLESPACE GCD_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE USER TEMPORARY TABLESPACE GCD_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE SYSTEM TEMPORARY TABLESPACE GCD_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;

db2 GRANT DBADM ON DATABASE TO user gcd;
db2 GRANT USE OF TABLESPACE GCD_TS TO user gcd;
db2 GRANT USE OF TABLESPACE GCD_TEMP_TS TO user gcd;

db2 UPDATE DB CFG FOR CP4BA USING APPLHEAPSZ 2560; #largest value
db2 CONNECT RESET;
EOSSH

echo
echo ">>>>$(print_timestamp) OS1 DB"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=manager-preparing-databases
# Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=vtdluwiifp-creating-db2-database-table-spaces-content-platform-engine-object-store
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 CONNECT TO CP4BA;
db2 CREATE LARGE TABLESPACE OS1_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE USER TEMPORARY TABLESPACE OS1_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE SYSTEM TEMPORARY TABLESPACE OS1_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;

db2 GRANT DBADM ON DATABASE TO user os1;
db2 GRANT USE OF TABLESPACE OS1_TS TO user os1;
db2 GRANT USE OF TABLESPACE OS1_TEMP_TS TO user os1;

db2 UPDATE DB CFG FOR CP4BA USING APPLHEAPSZ 2560; #largest value
db2 CONNECT RESET;
EOSSH

echo
echo ">>>>$(print_timestamp) Automation Application Engine (AAE) (application pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=pc-preparing-install-business-automation-workflow-runtime-workstream-services

echo
echo ">>>>$(print_timestamp) AAE DB"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=engine-creating-database
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 CONNECT TO CP4BA;
db2 CREATE REGULAR TABLESPACE AAE_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE USER TEMPORARY TABLESPACE AAE_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE SYSTEM TEMPORARY TABLESPACE AAE_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;

db2 GRANT DBADM ON DATABASE TO user aae;
db2 GRANT USE OF TABLESPACE AAE_TS TO user aae;
db2 GRANT USE OF TABLESPACE AAE_TEMP_TS TO user aae;
db2 CONNECT RESET;
EOSSH

echo
echo ">>>>$(print_timestamp) AAE Data persistence DB"
# Based on https://www.ibm.com/docs/en/filenet-p8-platform/[FNCM_KC_VERSION]?topic=vtdluwiifp-creating-db2-database-table-spaces-content-platform-engine-object-store
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 CONNECT TO CP4BA;
db2 CREATE LARGE TABLESPACE AEOS_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE USER TEMPORARY TABLESPACE AEOS_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE SYSTEM TEMPORARY TABLESPACE AEOS_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;

db2 GRANT DBADM ON DATABASE TO user aeos;
db2 GRANT USE OF TABLESPACE AEOS_TS TO user aeos;
db2 GRANT USE OF TABLESPACE AEOS_TEMP_TS TO user aeos;

db2 UPDATE DB CFG FOR CP4BA USING APPLHEAPSZ 2560; #largest value
db2 CONNECT RESET;
EOSSH

echo
echo ">>>>$(print_timestamp) Automation Document Processing (ADP) (document_processing pattern)"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=capabilities-preparing-install-automation-document-processing

echo
echo ">>>>$(print_timestamp) BASE DB"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=processing-preparing-db2-databases-document
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 CONNECT TO CP4BA;
db2 CREATE REGULAR TABLESPACE BASE_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE USER TEMPORARY TABLESPACE BASE_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE SYSTEM TEMPORARY TABLESPACE BASE_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;

db2 GRANT DBADM ON DATABASE TO user base;
db2 GRANT USE OF TABLESPACE BASE_TS TO user base;
db2 GRANT USE OF TABLESPACE BASE_TEMP_TS TO user base;
db2 CONNECT RESET;
EOSSH

echo
echo ">>>>$(print_timestamp) TENANT1 DB"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=processing-preparing-db2-databases-document
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 create database TENANT1 automatic storage YES USING CODESET UTF-8 TERRITORY DEFAULT COLLATE USING SYSTEM PAGESIZE 32768;
db2 UPDATE DATABASE CONFIGURATION FOR TENANT1 USING LOGFILSIZ 7500;
db2 UPDATE DATABASE CONFIGURATION FOR TENANT1 USING LOGPRIMARY 15;
db2 UPDATE DATABASE CONFIGURATION FOR TENANT1 USING APPLHEAPSZ 2560; 
db2 UPDATE DATABASE CONFIGURATION FOR TENANT1 USING STMTHEAP 8192;
db2 CONNECT TO TENANT1;
db2 DROP TABLESPACE USERSPACE1;
db2 CREATE Bufferpool TENANT1BP IMMEDIATE SIZE -1 PAGESIZE 32K;
db2 CREATE Bufferpool TENANT1TEMPBP IMMEDIATE SIZE -1 PAGESIZE 32K;
db2 CREATE Bufferpool TENANT1SYSBP IMMEDIATE SIZE -1 PAGESIZE 32K;
db2 CREATE LARGE TABLESPACE TENANT1DATA PAGESIZE 32K BUFFERPOOL TENANT1BP;
db2 CREATE USER TEMPORARY TABLESPACE USERTEMP1 PAGESIZE 32K BUFFERPOOL TENANT1TEMPBP;
db2 CREATE SYSTEM TEMPORARY TABLESPACE TEMPSYS1 PAGESIZE 32K BUFFERPOOL TENANT1SYSBP;
db2 GRANT CONNECT,DATAACCESS,CREATETAB ON DATABASE TO USER db2inst1;
db2 GRANT USE OF TABLESPACE TENANT1DATA TO user db2inst1;
db2 GRANT USE OF TABLESPACE USERTEMP1 TO user db2inst1;
db2 CONNECT RESET;
db2 activate db TENANT1
EOSSH

echo
echo ">>>>$(print_timestamp) TENANT2 DB"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=processing-preparing-db2-databases-document
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 create database TENANT2 automatic storage YES USING CODESET UTF-8 TERRITORY DEFAULT COLLATE USING SYSTEM PAGESIZE 32768;
db2 UPDATE DATABASE CONFIGURATION FOR TENANT2 USING LOGFILSIZ 7500;
db2 UPDATE DATABASE CONFIGURATION FOR TENANT2 USING LOGPRIMARY 15;
db2 UPDATE DATABASE CONFIGURATION FOR TENANT2 USING APPLHEAPSZ 2560; 
db2 UPDATE DATABASE CONFIGURATION FOR TENANT2 USING STMTHEAP 8192;
db2 CONNECT TO TENANT2;
db2 DROP TABLESPACE USERSPACE1;
db2 CREATE Bufferpool TENANT2BP IMMEDIATE SIZE -1 PAGESIZE 32K;
db2 CREATE Bufferpool TENANT2TEMPBP IMMEDIATE SIZE -1 PAGESIZE 32K;
db2 CREATE Bufferpool TENANT2SYSBP IMMEDIATE SIZE -1 PAGESIZE 32K;
db2 CREATE LARGE TABLESPACE TENANT2DATA PAGESIZE 32K BUFFERPOOL TENANT2BP;
db2 CREATE USER TEMPORARY TABLESPACE USERTEMP1 PAGESIZE 32K BUFFERPOOL TENANT2TEMPBP;
db2 CREATE SYSTEM TEMPORARY TABLESPACE TEMPSYS1 PAGESIZE 32K BUFFERPOOL TENANT2SYSBP;
db2 GRANT CONNECT,DATAACCESS,CREATETAB ON DATABASE TO USER db2inst1;
db2 GRANT USE OF TABLESPACE TENANT2DATA TO user db2inst1;
db2 GRANT USE OF TABLESPACE USERTEMP1 TO user db2inst1;
db2 CONNECT RESET;
db2 activate db TENANT2
EOSSH

echo
echo ">>>>$(print_timestamp) DEVOS1 DB"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=processing-preparing-db2-databases-document
# DEVOS Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=vtdluwiifp-creating-db2-database-table-spaces-content-platform-engine-object-store
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 CONNECT TO CP4BA;
db2 CREATE LARGE TABLESPACE DEVOS1_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE USER TEMPORARY TABLESPACE DEVOS1_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE SYSTEM TEMPORARY TABLESPACE DEVOS1_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;

db2 GRANT DBADM ON DATABASE TO user devos1;
db2 GRANT USE OF TABLESPACE DEVOS1_TS TO user devos1;
db2 GRANT USE OF TABLESPACE DEVOS1_TEMP_TS TO user devos1;

db2 UPDATE DB CFG FOR CP4BA USING APPLHEAPSZ 2560; #largest value
db2 CONNECT RESET;
EOSSH

echo
echo ">>>>$(print_timestamp) ADP prepare DB init files"
oc cp cert-kubernetes/ACA/configuration-ha/DB2 db2/c-db2ucluster-db2u-0:/tmp/_adp_tmp_DB2 -c db2u
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
mkdir -p sqllib/_adp_tmp
exit
sudo mv /tmp/_adp_tmp_DB2 /mnt/blumeta0/home/db2inst1/sqllib/_adp_tmp/DB2
sudo chown -R db2inst1:db2iadm1 /mnt/blumeta0/home/db2inst1/sqllib/_adp_tmp/DB2
EOSSH

echo
echo ">>>>$(print_timestamp) ADP init DBs"
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
# Init BASE DB
cd sqllib/_adp_tmp/DB2
chmod +x InitBaseDB.sh
echo "CP4BA
base
y" | ./InitBaseDB.sh

# Init TenantsDBs
chmod +x InitTenantDB.sh

# Init TENANT1 DB
echo "TENANT1
TENANT1
TENANT1
No
db2inst1
${UNIVERSAL_PASSWORD}
${UNIVERSAL_PASSWORD}
default
CP4BA
base
y" | ./InitTenantDB.sh

# Init TENANT2 DB
echo "TENANT2
TENANT2
TENANT2
No
db2inst1
${UNIVERSAL_PASSWORD}
${UNIVERSAL_PASSWORD}
default
CP4BA
base
y" | ./InitTenantDB.sh

EOSSH

echo
echo ">>>>$(print_timestamp) Business Automation Workflow Authoring (BAWAUT)"

echo
echo ">>>>$(print_timestamp) Set DB2_WORKLOAD"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=authoring-creating-required-databases
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2set DB2_WORKLOAD=FILENET_CM
EOSSH

echo
echo ">>>>$(print_timestamp) BADOCS DB"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=authoring-creating-required-databases
# BADOCS, BATOS, BADOS Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=vtdluwiifp-creating-db2-database-table-spaces-content-platform-engine-object-store
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 CONNECT TO CP4BA;
db2 CREATE LARGE TABLESPACE BADOCS_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE USER TEMPORARY TABLESPACE BADOCS_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE SYSTEM TEMPORARY TABLESPACE BADOCS_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;

db2 GRANT DBADM ON DATABASE TO user badocs;
db2 GRANT USE OF TABLESPACE BADOCS_TS TO user badocs;
db2 GRANT USE OF TABLESPACE BADOCS_TEMP_TS TO user badocs;

db2 UPDATE DB CFG FOR CP4BA USING APPLHEAPSZ 2560; #largest value
db2 CONNECT RESET;
EOSSH

echo
echo ">>>>$(print_timestamp) BATOS DB"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=authoring-creating-required-databases
# BADOCS, BATOS, BADOS Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=vtdluwiifp-creating-db2-database-table-spaces-content-platform-engine-object-store
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 CONNECT TO CP4BA;
db2 CREATE LARGE TABLESPACE BATOS_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE USER TEMPORARY TABLESPACE BATOS_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE SYSTEM TEMPORARY TABLESPACE BATOS_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;

db2 GRANT DBADM ON DATABASE TO user batos;
db2 GRANT USE OF TABLESPACE BATOS_TS TO user batos;
db2 GRANT USE OF TABLESPACE BATOS_TEMP_TS TO user batos;

db2 UPDATE DB CFG FOR CP4BA USING APPLHEAPSZ 2560; #largest value
db2 CONNECT RESET;
EOSSH

echo
echo ">>>>$(print_timestamp) BADOS DB"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=authoring-creating-required-databases
# BADOCS, BATOS, BADOS Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=vtdluwiifp-creating-db2-database-table-spaces-content-platform-engine-object-store
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 CONNECT TO CP4BA;
db2 CREATE LARGE TABLESPACE BADOS_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE USER TEMPORARY TABLESPACE BADOS_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE SYSTEM TEMPORARY TABLESPACE BADOS_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;

db2 GRANT DBADM ON DATABASE TO user bados;
db2 GRANT USE OF TABLESPACE BADOS_TS TO user bados;
db2 GRANT USE OF TABLESPACE BADOS_TEMP_TS TO user bados;

db2 UPDATE DB CFG FOR CP4BA USING APPLHEAPSZ 2560; #largest value
db2 CONNECT RESET;
EOSSH

echo
echo ">>>>$(print_timestamp) BAWAUT DB"
# Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=authoring-creating-required-databases
# BAWAUTDB Based on https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/21.0.x?topic=crd-creating-required-databases-in-db2
oc rsh -n db2 -c db2u c-db2ucluster-db2u-0 << EOSSH
su - db2inst1
db2 CONNECT TO CP4BA;
db2 CREATE REGULAR TABLESPACE BAWAUT_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE USER TEMPORARY TABLESPACE BAWAUT_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
db2 CREATE SYSTEM TEMPORARY TABLESPACE BAWAUT_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;

db2 GRANT DBADM ON DATABASE TO user bawaut;
db2 GRANT USE OF TABLESPACE BAWAUT_TS TO user bawaut;
db2 GRANT USE OF TABLESPACE BAWAUT_TEMP_TS TO user bawaut;

db2 UPDATE DB CFG FOR CP4BA USING LOGFILSIZ 16384 DEFERRED; #largest value
db2 UPDATE DB CFG FOR CP4BA USING LOGSECOND 64 IMMEDIATE; #largest value
db2 CONNECT RESET;
EOSSH

echo
echo ">>>>$(print_timestamp) Add DBs to DB2MC"

echo
echo ">>>>$(print_timestamp) Get auth token"
AUTH_TOKEN=`curl -k -X POST \
https://db2mc.${OCP_APPS_ENDPOINT}/dbapi/v4/auth/tokens \
-H 'content-type: application/json' \
-d '{"userid":"cpadmin","password":"'${UNIVERSAL_PASSWORD}'"}' | jq -r '.token'`

echo
echo ">>>>$(print_timestamp) Add DB connections to DB2MC"
add_db2mc_connection CP4BA
sleep 5
add_db2mc_connection TENANT1
sleep 5
add_db2mc_connection TENANT2
sleep 5

echo
echo ">>>>$(print_timestamp) Create CP4BA Mongo DBs"
oc rsh -n mongodb deployment/mongodb << EOSSH
mongo --username root --password ${UNIVERSAL_PASSWORD} --authenticationDatabase admin <<EOF
use ads
use ads-git
use ads-history
EOF
EOSSH

echo
echo ">>>>$(print_timestamp) CP4BA dbs install completed"
