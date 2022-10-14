# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

## [Unreleased]

### Added

- Update procedure description.
- Post deployment steps for IPM.
- All OpenLdap users now have separate mailboxes.
- Enabled ODM Decision warehouse schemas.

### Changed

- Updated CP4BA to 22.0.1.3.
- Updated RPA to 21.0.5.
- Updated IPM to 1.13.1.
- Updated extras.
- Moved repository and branch settings from Jobs to ConfigMap.

### Removed

- Ability to install on OpenShift 4.8.

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
