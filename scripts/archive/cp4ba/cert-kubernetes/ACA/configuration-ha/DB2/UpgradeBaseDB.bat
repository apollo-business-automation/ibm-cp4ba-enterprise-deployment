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

set /p base_db_name= Please enter a valid value for the base database name :
set /p base_db_user= Please enter a valid value for the base database user name :


echo
echo "-- Please confirm these are the desired settings:"
echo " - Base database name: %base_db_name%"
echo " - Base database user name: %base_db_user%"

set /P c=Are you sure you want to continue[Y/N]?
if /I "%c%" EQU "Y" goto :DOUPGRADE
if /I "%c%" EQU "N" goto :DOEXIT

:DOUPGRADE
    copy /Y sql\UpgradeBaseDB_21.0.2_to_21.0.3.sql.template sql\UpgradeBaseDB_21.0.2_to_21.0.3.sql
	powershell -Command "(gc sql\UpgradeBaseDB_21.0.2_to_21.0.3.sql) -replace '\$base_db_name', '%base_db_name%' | Out-File -encoding ascii sql\UpgradeBaseDB_21.0.2_to_21.0.3.sql
	powershell -Command "(gc sql\UpgradeBaseDB_21.0.2_to_21.0.3.sql) -replace '\$base_db_user', '%base_db_user%' | Out-File -encoding ascii sql\UpgradeBaseDB_21.0.2_to_21.0.3.sql
	echo "Running upgrade script: sql/UpgradeBaseDB_21.0.2_to_21.0.3.sql"
    db2 -tvf sql/UpgradeBaseDB_21.0.2_to_21.0.3.sql
	goto END
:DOEXIT
	echo "Exited on user input"
	goto END
:END
	echo "Script completed."

ENDLOCAL
