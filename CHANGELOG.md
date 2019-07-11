# Changelog for Zeus and Commuter Rails Apps

This file documents notable changes to the apps for each release, including:

* core source code shared by all Zeus and Commuter Rails apps
* database schema definitions and updates
* app configuration files

The format of this file is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

In short this means that version numbers, visible here and on the login page of the
app match, and have a predictable format indicating how much change from the previous
version has occurred.

The [Unreleased](#[unreleased]) section collects notes for unreleased changes and features, until they are absorbed into a formal release in a version number tagged section below.

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
- [Admin] A special section filter for *IS NULL* no longer returns an error
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
