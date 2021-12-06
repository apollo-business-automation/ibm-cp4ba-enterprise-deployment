# RPA post-deploy

The following list specifies when you need to perform particular post-deployment steps
- [Install RPA Client](#install-rpa-client) - When you want to develop robots you need this to install Studio.
- [Create vault password](#create-vault-password) - When you want to use Credentials in your RPA solution.
- [Update chromedriver for studio](#update-chromedriver-for-studio) - When you want to use commands that use Chrome browser.

## Install RPA Client

Based on https://www.ibm.com/docs/en/rpa/20.12?topic=premises-client-installation

You need to download IBM Robotic Process Automation Client Installer (G00PWZX) as IRPA_Client_Installer.zip from PPA  
Unzip IRPA_Client_Installer.zip  
Execute RPA Client install script with the following command. It also installs Studio.  
```cmd
"IBM RPA Client Install.exe" /exenoui /qn installlevel=4 tenantcode=5000 licenseapiaddress=https://rpa-apiserver-{{CP4BA_PROJECT_NAME}}.{{OCP_APPS_ENDPOINT}}/
```
Wait until the installation is completed. You can use provided [client-install-wait.cmd](https://github.com/apollo-business-automation/ibm-cp4ba-enterprise-deployment/blob/main/scripts/rpa/client-install-wait.cmd) (from the repository) to wait for install process to finish.  

## Create vault password

In Windows system tray, find Vault, right click it and choose *Open*  
Password: {{UNIVERSAL_PASSWORD}}  
Re-Type Password: {{UNIVERSAL_PASSWORD}}  
Click *Confirm*

## Update chromedriver for studio

Based on https://www.ibm.com/docs/en/rpa/20.12?topic=twarpa-google-chrome-binary-file-is-not-found-when-starting-browser-instance

Take note of which Chrome version you are using  
Download the appropriate chromedriver from here (don't worry about 32 or 64bit, this driver works for both) https://chromedriver.chromium.org/downloads  
Navigate to WDG folder under AppData - the version may differ (C:/Users/Administrator/AppData/Local/WDG Automation/packages/20.12.5.0)  
Make backup of the current chromedriver.exe  
Paste new chromedriver.exe  
