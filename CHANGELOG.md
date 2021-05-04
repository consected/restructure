# Changelog for Zeus and Commuter Rails Apps

This file documents notable changes to the apps for each release, including:

- core source code shared by all Zeus and Commuter Rails apps
- database schema definitions and updates
- app configuration files

The format of this file is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

In short this means that version numbers, visible here and on the login page of the
app match, and have a predictable format indicating how much change from the previous
version has occurred.

The **Unreleased** section collects notes for unreleased changes and features, until they are absorbed into a formal release in a version number tagged section below.

## Unreleased


## [7.3.219] - 2021-05-04


## [7.3.218] - 2021-04-20


## [7.3.217] - 2021-04-20


## [7.3.216] - 2021-04-19


## [7.3.215] - 2021-04-16


## [7.3.214] - 2021-04-16


## [7.3.213] - 2021-04-16


## [7.3.212] - 2021-04-13


## [7.3.211] - 2021-04-13


## [7.3.210] - 2021-03-26


## [7.3.209] - 2021-03-25


## [7.3.208] - 2021-03-25


## [7.3.207] - 2021-03-25


## [7.3.206] - 2021-03-18


## [7.3.204] - 2021-03-12


## [7.3.201] - 2021-03-02


## [7.3.200] - 2021-02-23


## [7.3.199] - 2021-02-23


## [7.3.198] - 2021-02-22


## [7.3.197] - 2021-02-19


## [7.3.196] - 2021-02-19


## [7.3.195] - 2021-02-19


## [7.3.194] - 2021-02-19


## [7.3.193] - 2021-02-08


## [7.3.192] - 2021-01-18

- [Added] server information in admin panel, and moved server restart to it
- [Added] after login or navigate to '/' redirect to "logo url" as home page

## [7.3.191] - 2021-01-18


## [7.3.191] - 2021-01-18


## [7.3.190] - 2021-01-15


## [7.3.189] - 2021-01-15


## [7.3.188] - 2021-01-14


## [7.3.187] - 2021-01-14


## [7.3.186] - 2021-01-14


## [7.3.185] - 2021-01-13


## [7.3.184] - 2021-01-13


## [7.3.183] - 2021-01-13


## [7.3.182] - 2021-01-11


## [7.3.181] - 2021-01-11

- [Added] Scripted jobs functionality in filestore pipelines
- [Added] Standalone pages in layouts include web page styled views and file folders
- [Added] improved migration generation and create_or_update migrations generated on app type export
- [Added] External identifiers now use option configurations to apply dynamic definitions to fields and forms
- [Added] improved DB table and field comments, automatically generated from captions and labels
- [Added] activity_selector reference option
- [Changed] item_flags table now enforces not null on item_flag_name_id to avoid data causing app errors
- [Changed] app types now import / export item flag name configurations
- [Changed] improved image previewing and icons
- [Changed] bugfixes in editable report forms and model reference edit buttons
- [Changed] model reference handling in views
- [Changed] Activity Log admin edit form to provide more information about the current definition
- [Fixed] bugfixes in editable report forms and model reference edit buttons
- [Fixed] many fixes

## [7.3.168] - 2020-11-20

- [Added] improved migration generation and create_or_update migrations generated on app type export
- [Added] External identifiers now use option configurations to apply dynamic definitions to fields and forms
- [Added] improved DB table and field comments, automatically generated from captions and labels
- [Added] activity_selector reference option
- [Changed] model reference handling in views
- [Changed] Activity Log admin edit form to provide more information about the current definition
- [Fixed] many fixes

## [7.3.167] - 2020-11-12

## [7.3.163] - 2020-11-11

- [Changed] small bugfixes and build to support release to Filestore

## [7.3.151] - 2020-11-07

- [Added] templates for activity logs and dynamic models are displayed using the version current at the time a record was created
- [Added] versioned UI templates downloading based on data being retrieved
- [Added] data dictionary, schema and classification types viewing by authorized users
- [Added] [Filestore] option for certain users to re-run all actions (extract zip and handle metadata)
- [Added] [Admin] allow admins to view a list of other admins and disable individual admin accounts
- [Added] [Admin] automated database migration creation based on changes to configurations
- [Added] [Filestore] deidentification / metadata changes within user triggered pipelines
- [Changed] git repos for FPHS specific app configurations and Docker container for building production assets
- [Changed] removed Javascript packages from direct inclusion in source and instead install from Yarn
- [Changed] updated platform to Rails 5.2
- [Fixed] bugs and usability issues

## [7.3.83] - 2020-01-13

- [Added] [IPA] sync-back participant data and events to Zeus
- [Added] Enahncements allowing more complex forms to be defined in activities
- [Added] [Sleep Study] configurations to cover screener changes
- [Added] [IPA] participant summary changes
- [Added] [Bulk SMS] capture opt-outs from AWS
- [Added] [GRIT Study] preparations for GRIT release
- [Added] [Zeus] Scantron Q2 table
- [Added] Configurations allow alternatives to player info in search results headers
- [Added] [Admin] improvements to support admin configurations of applications and user roles
- [Fixed] Small bug fixes

## [7.3.59] - 2019-10-17

- [Added] [Sleep Study] configurations for Athena app
- [Added] [Bulk Msg] app for SMS marketing
- [Added] [Zeus] External Identifier for Q1 redcap links
- [Added] [Zeus] External Identifier for Q2 redcap links
- [Added] [Zeus] External Identifier for Marketo IDs
- [Added] [Zeus] External Identifier for Sleep Study IDs
- [Added] [Zeus] Authorized users can view added identifiers based on role assignments
- [Fixed] Many bug fixes

## [7.3.49] - 2019-09-23

- [Added] [IPA] Participant Summary panel, pulling data from phone screen responses
- [Added] [IPA] Reimbursement request added to IPA Tracker Payments block
- [Added] [IPA] Automatically update player details with birth date from phone screener
- [Added] WYSIWYG editor / viewing for notes fields
- [Added] Much improved styling
- [Added] Many changes to improve configuration of apps
- [Added] Allow re-syncing from Zeus to Athena with a new IPA ID
- [Added] Improved flexibility for email and SMS notifications
- [Added] [Filestore] Allow file rename, move and improved send-to-trash by authorized users
- [Fixed] [Filestore] Identify DICOM files based on content, not just filename
- [Fixed] Many bug fixes

## [7.3.21] - 2019-07-03

- [Added] Dashboards include timeseries charts
- [Added] [IPA] Phone screen comprehension questions

## [7.3.10] - 2019-06-24

- [Added] [IPA] Changed flow and script of Phone Screener, added specific fields to TMS and updated eligibility call
- [Added] View specific reports with a chart view, such as pie or histogram
- [Added] Calendar view on specific reports
- [Added] [Bulk-SMS] An app configuration (and associated code changes) to allow sending bulk SMS messages to player contacts
- [Added] Changes to support better modularization of apps and generating baseline components as building blocks for new apps
- [Fixed] Performance and admin configuration bugs
- [Fixed] [Filestore] Issue uploading under certain circumstances

## [7.2.28] - 2019-05-21

- [Added] [IPA] Deployed Medical Navigation app to production
- [Fixed] Accidentally allowed users to view reports page for a search they have, even if report viewing is disabled

## [7.2.25] - 2019-05-16

- [Added] Define a prefix for master record header, based on data extracted from the record
- [Added] Message field substitution allows data from any part of the master record to be used

## [7.2.24] - 2019-05-15

- [Added] [IPA] Auto search tabs / queues showing participants with various statuses (such as Ready for Sign Off)
- [Changed] [IPA] Outstanding Activities search / report has some new activities to clarify meanings
- [Added] Loading / refresh of page should be much faster after the first load

## [7.2.23] - 2019-05-15

- [Added] [IPA] Added MRN activity to Navigation to allow viewing and adding of MRNs from the planning / scheduling process (plus associated 'scheduling' role)
- [Added] [IPA] New search tab queues representing common Outstanding Activities searches, such as "Ready to Sign" phone screen checklist
- [Added] [Filestore] Allow record attributes to be substituted into filename filters, to enforce names like "{{ids.ipa_id}}-filename" to become "123123-filename"
- [Fixed] Bug causing errors when referencing external IDs (such as IPA ID) from an activity

## [7.2.17] - 2019-05-03

- [Changed] Login and e-signature forms used the term "one-time code", which was confusing to users. Change to "two-factor authentication code" for clarity.
- [Changed] [IPA] Fixed a bug in the configuration that was preventing PIs from e-signing phone screen checklist documents
- [Added] [Admin] Allow admins to copy configuration entries in admin panel, to allow accurate duplication of templates and common configurations
- [Added] [Filestore] [Access-Controls] Uploaded files can be be sent to trash, which is a hidden directory and hidden stored / archived files paths
- [Changed] [Filestore] Added configuration option to notify roles when a set of file uploads has completed
- [Changed] [Filestore] Fixed issues with background processing of zip files based on testing in production with real MRI files
- [Changed] [Filestore] Speed up browsing of containers with thousands of files

## [7.2.14] - 2019-04-17

- [Changed] [IPA] TMS review discussion to include Staff Member
- [Changed] [IPA] Navigation Planned Events and Event Feedback adds PI Assigned to Coordinate, and Location
- [Changed] [Filestore] Provide a mechanism for notifying users after a set of files has been uploaded successfully
- [Fixed] Bug preventing editable reports working correctly
- [Fixed] Bug that showed the MSID style searches in the nav bar when requesting the two factor authentication QR code setup the first time
- [Fixed] [Filestore] Ensure that filenames are checked against filters for every file in a multiple upload
- [Changed] Allow checkboxes to be used in editable forms

## [7.2.13] - 2019-04-16

- [Fixed] Bug that allowed files with names that didn't match filters to be uploaded if the first file did match

## [7.2.12] - 2019-04-12

- [Changed] Allow configuration of one time code drift (to account for different authenticator apps and time drift between phones and server)
- [Changed] Allow per-server configuration of number of password attempts before lockout
- [Fixed] Ensure e-signature one time code accounts for time drift during signature

## [7.2.11] - 2019-04-11

- [Fixed] [Filestore] Some archives didn't finish processing

## [7.2.10] - 2019-04-11

- [Fixed] Bug where date picker would show one date but the form would return the previous day's date

## [7.2.9] - 2019-04-09

- [Fixed] [Filestore] Fixed bug checking for duplicate file uploads
- [Added] [API] API samples for Filestore uploads and to create containers

## [7.2.8] - 2019-04-08

- [Fixed] [Filestore] Allow large file uploads through the API to complete without using all the server's memory
- [Fixed] [Secure-View] Only count pages when the file is convertible to a PDF, avoiding unnecessary delays in viewing

## [7.2.7] - 2019-04-08

- [Fixed] Bug preventing a user of Athena from accessing the default IPA Files app on Medusa

## [7.2.5] - 2019-04-05

- [Fixed] Bug in one-time code pattern prevented correct entry in admin login and e-signature

## [7.2.4] - 2019-04-03

### Fixed

- [Build] Testing improved build process to add branch to Github

## [7.2.3] - 2019-04-03

### Changed

- [UI] Made the one-time code field for login and electronic signatures show the entered digits, to make entry more reliable and avoid issues with password managers attempting to save the code
- [Config] [IPA] Changes to notify MedNav on finalization of phone screener

### Fixed

- [Admin] A special section filter for _IS NULL_ no longer returns an error
- [Docs] Fixed issues in the new deployment readme for secure-view installations

## [7.2.2] - 2019-03-29

### Added

- [Docs] Added secure-view readme to support building and installation of server-side programs required for creating previews

### Fixed

- [UI] [Secure-View] Make the HTML preview zoom in a more usable way
- [UI] [Access-Controls] [Secure-View] Manage which roles / users can preview as image, HTML, or can download

## [7.2.1] - 2019-03-29

### Added

- [Secure-View] Provide a secure-viewer directly for users clicking a file link in a filestore container. Just view the pages of documents directly in the browser without having to worry about where files were downloaded, or cleaning them up afterwards.

## [7.2.15] - 2019-04-18

## [7.2.18] - 2019-05-03

## [7.2.19] - 2019-05-03

## [7.2.20] - 2019-05-05

## [7.2.21] - 2019-05-08

## [7.2.22] - 2019-05-08

## [7.2.26] - 2019-05-16

## [7.2.27] - 2019-05-17

## [7.2.28] - 2019-05-20

## [7.2.29] - 2019-05-23

## [7.3.1] - 2019-06-10

## [7.3.2] - 2019-06-11

## [7.3.3] - 2019-06-14

## [7.3.4] - 2019-06-14

## [7.3.5] - 2019-06-17

## [7.3.6] - 2019-06-18

## [7.3.7] - 2019-06-18

## [7.3.8] - 2019-06-19

## [7.3.9] - 2019-06-21

## [7.3.10] - 2019-06-24

## [7.3.11] - 2019-06-24

## [7.3.12] - 2019-06-24

## [7.3.13] - 2019-06-25

## [7.3.14] - 2019-06-27

## [7.3.15] - 2019-06-27

## [7.3.16] - 2019-06-27

## [7.3.17] - 2019-06-28

## [7.3.18] - 2019-07-01

## [7.3.19] - 2019-07-02

## [7.3.20] - 2019-07-03

## [7.3.21] - 2019-07-03

## [7.3.22] - 2019-07-08

## [7.3.23] - 2019-07-08

## [7.3.24] - 2019-07-10

## [7.3.25] - 2019-07-11

## [7.3.26] - 2019-07-15

## [7.3.27] - 2019-07-15

## [7.3.28] - 2019-07-16

## [7.3.29] - 2019-07-16

## [7.3.30] - 2019-07-17

## [7.3.31] - 2019-07-17

## [7.3.32] - 2019-07-17

## [7.3.33] - 2019-07-24

## [7.3.34] - 2019-07-30

## [7.3.35] - 2019-08-01

## [7.3.36] - 2019-08-07

## [7.3.37] - 2019-08-23

## [7.3.38] - 2019-08-23

## [7.3.39] - 2019-09-02

## [7.3.40] - 2019-09-03

## [7.3.41] - 2019-09-04

## [7.3.42] - 2019-09-05

## [7.3.43] - 2019-09-05

## [7.3.44] - 2019-09-11

## [7.3.45] - 2019-09-11

## [7.3.46] - 2019-09-11

## [7.3.47] - 2019-09-19

## [7.3.48] - 2019-09-19

## [7.3.49] - 2019-09-20

## [7.3.50] - 2019-09-30

## [7.3.51] - 2019-10-01

## [7.3.52] - 2019-10-01

## [7.3.53] - 2019-10-02

## [7.3.54] - 2019-10-04

## [7.3.55] - 2019-10-06

## [7.3.56] - 2019-10-08

## [7.3.57] - 2019-10-09

## [7.3.58] - 2019-10-09

## [7.3.60] - 2019-10-18

## [7.3.61] - 2019-10-18

## [7.3.62] - 2019-10-25

## [7.3.63] - 2019-10-25

## [7.3.64] - 2019-10-28

## [7.3.65] - 2019-10-28

## [7.3.66] - 2019-10-29

## [7.3.67] - 2019-10-29

## [7.3.68] - 2019-10-31

## [7.3.69] - 2019-11-01

## [7.3.70] - 2019-11-01

## [7.3.71] - 2019-11-08

## [7.3.72] - 2019-11-08

## [7.3.73] - 2019-11-11

## [7.3.74] - 2019-11-15

## [7.3.75] - 2019-11-18

## [7.3.76] - 2019-11-18

## [7.3.77] - 2019-11-18

## [7.3.78] - 2019-11-21

## [7.3.79] - 2019-11-25

## [7.3.80] - 2019-12-03

## [7.3.81] - 2019-12-04

## [7.3.82] - 2019-12-05

## [7.3.83] - 2020-01-08

## [7.3.85] - 2020-01-15

## [7.3.86] - 2020-01-20

## [7.3.87] - 2020-01-24

## [7.3.88] - 2020-01-29

## [7.3.89] - 2020-03-09

## [7.3.90] - 2020-03-09

## [7.3.91] - 2020-03-13

## [7.3.92] - 2020-03-24

## [7.3.93] - 2020-03-24

## [7.3.94] - 2020-03-27

## [7.3.95] - 2020-03-27

## [7.3.97] - 2020-04-03

## [7.3.98] - 2020-04-03

## [7.3.99] - 2020-04-03

## [7.3.100] - 2020-04-03

## [7.3.101] - 2020-04-06

## [7.3.102] - 2020-04-06
