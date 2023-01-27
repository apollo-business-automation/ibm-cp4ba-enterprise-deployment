# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

## [Unreleased]

### Added

- Post deploy steps documentation for ICN Sync, Edit Service and Microsoft Office.
- CloudBeaver as UI for MSSQL server. Requires new cloudbeaver_enabled configuration option to be set.

### Changed

- Updated CP4BA to 22.0.2 IF001. 
- Updated RPA to 23.0.1. 
- Switch RPA client install instructions from command line to wizard.
- Switch Task Mining client install instructions from command line to wizard.

### Fixed

- Cleanup PVCs during RPA removal to prevent potential failures during repetitive installations.   

## [2023-01-09]

### Fixed

- Postgres network configuration error appearing in some environments due to pod restart in init phase.
- Scenario of BAW installation without BAI, fix for PFS and BAS not starting correctly.

## [2022-12-21]

### Added

- PostgreSQL deployment.
- pgAdmin for PostgreSQL UI administration.
- Configuration for PM redis installation.
- Extra task manager for flink for external event processing.

### Changed

- Updated CP4BA to 22.0.2.
- Updated RPA to 23.0.0.
- Update IPM to 1.13.2.
- Default domain for users/emails changed from cp.local to cp.internal as .local has other special meaning and should not be used.
- Non ADP databases switched from DB2 to PostgreSQL.
- Separate DB2 DB for ADP Base is created.
- Separate DB2 DB for IPM Task Mining is created.
- Enabled RPA NLP by default.

### Fixed

- Wrong Project Area connection definition for BAW.

## [2022-12-05]

### Added

- MongoDB exposed as NodePort for debugging and CLI connection documented.
- Added privileged permission to Nexus as newly required by the Deployment.

### Changed

- Updated CP4BA to 22.0.1 IF005.
- Updated CPFS to 3.22.
- Switched CPFS from single instance mode to multiple instances mode.

## [2022-11-18]

### Added

- Update procedure description.
- Post deployment steps for IPM.
- All OpenLdap users now have separate mailboxes.
- Enabled ODM Decision warehouse schemas.
- Workflow system enabled on OS1.
- Configuration for ADP GPU node.
- Configuration for RPA NLP replicas.
- Main admin automatically permitted to develop RPA bots.
- Automatic git project creation for ADS.
- Enabled CSS on DEVOS1 for ADP.
- Task mining master key set automatically.
- Task mining related permissions given to admin user automatically.
- Task mining admin user enabled for TM agent.

### Changed

- Updated CP4BA to 22.0.1.4.
- Updated RPA to 21.0.7.
- Updated IPM to 1.13.1.
- Updated extras.
- Moved repository and branch settings from Jobs to ConfigMap - breaking change.
- Merged separate Secrets into one config Secret - breaking change.

### Removed

- Ability to install on OpenShift 4.8.
- CPFS grafana operator as custom grafanas are deprecated in OCP 4.10 and removed in 4.11.

## [2022-09-20]

### Added

- Option to use custom LDAP.

### Changed

- Updated CP4BA to 22.0.1.2.
- Updated RPA to 21.0.4.

## [2022-08-10]

### Changed

- All IBM SW now uses pinned catalog sources to prevent issues with new version releases.

## [2022-08-05]

### Added

- Possibility to define which components should be deployed.

### Changed

- Updated CP4BA to 22.0.1.
- Updated RPA to 21.0.3.
- Updated IPM to 1.13.0.
- Updated the config map example with definition of which components should be deployed.

### Fixed

- IPM installation now completes successfully and doesn't break IAF operator.

## [2022-06-07]

### Fixed

- Updated helm chart version of mongodb as previous version used was deleted from repo.

## [2022-05-31]

### Changed

- Updated CP4BA to 21.0.3.9 with pinned catalogs.
- Updated RPA to 21.0.2.5.
- Updated IPM to 1.12.0.5.

## [2022-05-17]

### Fixed

- Set ansible modules static version dependencies as latest versions break the deployment.

## [2022-05-10]

### Added

- Automated some IER configuration steps.
- Automated Task Manager connection settings in Navigator.
- Automated enabling of Navigator license files for Office and Redaction.

### Changed

- Updated CP4BA to 21.0.3.8 with pinned catalogs.
- Updated CPFS to 3.17.0.
- Updated RPA to 21.0.2.4.

## [2022-05-02]

### Added

- Object Stores and Route creation for IER.

### Fixed

- Added checking for nexus repository to prevent breaking it and reviving from its errors.

### Removed

- Obsolete post-deploy steps for Viewer as it now automatically include MS document types.

## [2022-04-11]

### Added

- Validations of inputs for installation.

### Changed

- AKHQ now uses jks as truststore without private key.
- Updated CPFS to 3.16.3.
- Updated CP4BA to 21.0.3.7 with pinned catalogs. Also resolves ADP not able to consume new documents.
- Removed entryuuid from OpenLDAP entries as they are not needed anymore.
- Updated DB2 to 11.5.7.
- Switched Task Manager to cpadmins and cpusers groups.
- Updated RPA to 21.0.2.3.
- Updated IPM to 1.12.0.4.
- Updated Asset Repo to 2021.4.1-3.

## [2022-03-15]

### Added

- Add deployment of IER with docs about post deployment steps.

### Changed

- Updated CPFS to 3.16.1

## [2022-03-08]

### Changed

- Switched implementation to Ansible
- Upgraded CP4BA to 21.0.3.5
- Upgraded Process Mining to 1.12.0.3
- Upgraded Asset Repo to 2021.4.1-2
- Upgraded RPA to 1.2.2

## [2022-01-12]

### Changed

- Switch all Operators and Containers to fixed versions
- Storage class doesn't have to be set as default now
- Upgraded CP4BA to 21.0.3
- Upgraded Process Mining to 1.12.0.2
- Upgraded Asset Repo to 2021.4.1-1
- ADS and IPM now uses external MongoDB

## [2021-09-03]

### Added

- Initial Content
