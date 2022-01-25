::
:: Licensed Materials - Property of IBM
:: 5737-I23
:: Copyright IBM Corp. 2018 - 2021. All Rights Reserved.
:: U.S. Government Users Restricted Rights:
:: Use, duplication or disclosure restricted by GSA ADP Schedule
:: Contract with IBM Corp.
::
@echo off

SETLOCAL

set /p tenant_db_name= Please enter a valid value for the tenant database name :
set /p tenant_ontology= Please enter a valid value for the tenant ontology name :

echo
echo "-- Please confirm these are the desired settings:"
echo " - tenant database name: %tenant_db_name%"
echo " - ontology name: %tenant_ontology%"

set /P c=Are you sure you want to continue[Y/N]?
if /I "%c%" EQU "Y" goto :DOUPGRADE
if /I "%c%" EQU "N" goto :DOEXIT

:DOUPGRADE
	copy /Y sql\UpgradeTenantDB_21.0.2_to_21.0.3.sql.template sql\UpgradeTenantDB_21.0.2_to_21.0.3.sql
	powershell -Command "(gc sql\UpgradeTenantDB_21.0.2_to_21.0.3.sql) -replace '\$tenant_db_name', '%tenant_db_name%' | Out-File -encoding ascii sql\UpgradeTenantDB_21.0.2_to_21.0.3.sql
	powershell -Command "(gc sql\UpgradeTenantDB_21.0.2_to_21.0.3.sql) -replace '\$tenant_ontology', '%tenant_ontology%' | Out-File -encoding ascii sql\UpgradeTenantDB_21.0.2_to_21.0.3.sql
	echo.
	echo "Running upgrade script sql\UpgradeTenantDB_21.0.2_to_21.0.3.sql ...."
	db2 -tvf sql\UpgradeTenantDB_21.0.2_to_21.0.3.sql
	goto END
:DOEXIT
	echo "Exited on user input"
	goto END
:END
	echo "END"

ENDLOCAL
