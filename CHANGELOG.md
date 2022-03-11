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

The [Unreleased](#unreleased) section collects notes for unreleased changes and features, until they are absorbed into a formal release in a version number tagged section below.

Note that not every tagged version may be suitable for production use. A Github
release will be created for any release tested in production, and may be marked below with the tag [Release]

## [7.4.96] - 2022-02-09

- [Fixed] issue with certain master record searches

## [7.4.98] - 2022-02-09

### Transferred from ReStructure @8.0.28 - 2022-03-08

- [Added] paths and resource names when referencing activity log types
- [Added] much more consistent handling of resource names with **Resources::Models**
- [Added] user profiles tabs definable using page layout definitions
- [Added] ability to include activity log type as a resource in a page layout definition
- [Added] **add_item_button** substitution for captions and report headers
- [Added] user definable user preferences for timezones and formats
- [Added] per-server caching of latest dynamic definition versions, to allow automated reloading on a page refresh
- [Added] view_options for references in activity log def to always open a reference
- [Added] new disk usage and host id information
- [Added] user_is_creator as references from: option, including for NFS store containers
- [Added] option to skip creating a container as a save trigger if one already exists with a matching name
- [Changed] to restart server on successful app import
- [Changed] NFS Store file download to ensure the file is correctly retrieved when a user is in a different app to the container
- [Changed] app migrations to ignore removed columns if ALLOW_DROP_COLUMNS not set
- [Fixed] handling of admin filters to consistently show correct app selection

## [7.4.96] - 2022-02-09

- [Fixed] pregenerated and non-editable external identifier fields not to show
- [Changed] export of app-export migrations to go to a single app directory, not each schema directory
- [Added] app admin navigation for current app
- [Fixed] Beanstalk scripts

## [7.4.95] - 2022-01-27

- [Updated] restart script to allow full EB restart of all app servers
- [Added] app type components page for easy viewing and navigation around an app
- [Added] ability to filter admin resources by id, ids or resource name

### Transferred from ReStructure @8.0.26

- [Added] user self-registration, email confirmation and password reset
- [Changed] release script to allow clean container to be requested
- [Changed] change_user_roles trigger to allow app_type to be specified
- [Changed] ability to specify multiple checkboxes in report select items
- [Changed] css for mobile responsiveness, css vars and app styles
- [Changed] document library to correctly link to source repository
- [Changed] admin scripts to improve server configuration
- [Fixed] issue with active app types when specified with env var, since it returned an array not a scope

## [7.4.94] - 2021-12-16

- [Added] scripted job script for OCR
- [Changed] scripted job for better job feedback and documentation
- [Changed] activity log documentation to improve filestore information
- [Added] logic to avoid too many refreshes on browser

## [7.4.93] - 2021-12-16

- [Fixed] multiple bugs

## [7.4.91] - 2021-12-03

- [Added] PDF and office doc search (within a single document) in secure view
- [Changed] report list functionality to results list view
- [Fixed] embedded items not updating in activity logs, causing entered data to be lost
- [Fixed] scrolling issue with report result lists (cherrypicked from upstream ReStructure)

## [7.4.90] - 2021-12-03

- [Added] restrict access to standalone pages / dashboards with user access controls
- [Fixed] rspec issues

## [7.4.89] - 2021-12-02

- [Added] configure an alt_column_header for reports
- [Added] allow substitutions in report descriptions and dashboard block headers
- [Added] substitution add*edit_button*
- [Added] disable dynamic definition versions based on app setting
- [Added] hiding of dashboards in list
- [Added] menu / title setting for dashboards (and reports)
- [Fixed] substitutions in forms with no master
- [Fixed] YAML/JSON field viewing and editing

## [7.4.88] - 2021-12-01

## [7.4.87] - 2021-12-01

- [Changed] - bump version

## [7.4.86] - 2021-12-01

## [7.4.85] - 2021-12-01

- [Changed] - bump version

## [7.4.84] - 2021-12-01

## [7.4.83] - 2021-12-01

## [7.4.82] - 2021-12-01

## [7.4.81] - 2021-11-30

- [Changed] - bump version

## [7.4.84] - 2021-12-01

- [Changed] - bump version

## [7.4.83] - 2021-12-01

- [Changed] - bump version

## [7.4.82] - 2021-12-01

## [7.4.81] - 2021-11-30

- [Changed] - bump version

## [7.4.80] - 2021-11-30

- [Changed] app-type import to prevent disabling user access controls if no config for valid_user_access_controls appear in the uploaded file
- [Fixed] bugfixes

## [7.4.79] - 2021-11-19

- [Changed] big select updated to allow filters and work with dynamic models
- [Changed] editable report lists can work without master_id

### Transferred from ReStructure @ 8.0.26

- [Added] better handling of report results list with full set of column types from the table
- [Added] report edit and criteria select fields to use models more effectively and provide grouping
- [Fixed] migrations with references that don't produce views

## [7.4.78] - 2021-11-19

- [Added] changes to allow report record edit and create to work with arbitrary models

## [7.4.77] - 2021-11-19

- [Fixed] multiple bugfixes related to report criteria configuration and select_from_model
- [Fixed] schema updated again for missing migration

## [7.4.76] - 2021-11-18

- [Fixed] *transposed_table* bad HTML markup

## [7.4.75] - 2021-11-18

- [Fixed] *transposed_table* not viewing correctly in emails

## [7.4.74] - 2021-11-18

- [Added] report view*as option to show results as a \_transposed_table*

## [7.4.73] - 2021-11-18

- [Added] handling of multi*editable* field type configs for lists and choices in forms
- [Added] column option for "choice_label" and ensure it works for all types of display and editing
- [Fixed] report edit forms and results format and submit dates correctly
- [Fixed] form, credential and trigger bugs
- [Fixed] bugfixes

### [7.4.71.1] - 2021-11-15

- [Added] Configuration of **\_constants** in extra options dynamic configuration
- [Added] Redcap now sets up dynamic model field configurations to display captions, labels and correct field types in edit and view modes
- [Added] Report results options added **embedded_block** to show dynamic models as forms from report results
- [Added] Contributor field to data dictionary variable records, to accompany target field.
- [Fixed] Template retrieval and post processing templates
- [Changed] Report results table significantly refactored

## [7.4.71] - 2021-11-01

- [Added] Add support for Redcap repeating instruments - Transferred from upstream ReStructure
- [Added] Report criteria field type **select_from_model**
- [Added] Derived variables in dynamic model data dictionary now update from their source variables
- [Added] Enhancements to dynamic model definition panels, especially around data dictionary
- [Fixed] DB comments now updating when a dynamic model is a view

## [7.4.70] - 2021-10-27

- [Fixed] Ensure views initialize with dynamic models

## [7.4.69] - 2021-10-26

- [Fixed] Fix issue with times in Redcap leading to constant updating of records

## [7.4.68] - 2021-10-26

## [7.4.68] - 2021-10-26

## [7.4.68] - 2021-10-26

## [7.4.67] - 2021-10-26

- [Changed] Bump version

## [7.4.66] - 2021-10-26

- [Changed] Allow dynamic model updates to add fields where there is no history table

## [7.4.65] - 2021-10-26

- [Added] Data dictionary handling for dynamic models and model generator
- [Added] Refresh dynamic model configuration from table structure
- [Added] Option to download app-export migrations from server as a zip
- [Added] Automatic creation of reference views based on model reference configs
- [Changed] Version of pg gem to avoid memory leaks
- [Changed] Model reference refactoring

## [7.4.65] - 2021-10-26

## [7.4.64] - 2021-10-18

- [Changed] Handling of tracker "alerts" to work without tracker panel being actively displayed
- [Changed] Browser back button in the secure viewer now just closes it
- [Changed] Gems updated, addressing Puma CVE and update to Dalli v3

## [7.4.63] - 2021-10-07

- [Fixed] Embedded reports autorunning even if "run automatically" was not set

## [7.4.62] - 2021-10-06

- [Fixed] [Filestore] file trigger action not working
- [Fixed] [Filestore] incorrect current user being used in certain cases preventing browser viewing
- [Fixed] [Filestore] loop related to unzipping when .z0n parts are missing

## [7.4.61] - 2021-09-21

- [Added] Small change to Study Info authoring display to style with extra classes

## [7.4.59] - 2021-09-20

- [Fixed] Study Info app authoring and display
- [Added] Model references disabled when to_record is disabled
- [Fixed] Calculation around boolean fields

## [7.4.58] - 2021-09-20

- [Changed] Study Info app to provide a better authoring experience
- [Changed] processing scripts to allow for app-specfic scripts to be loaded

## [7.4.57] - 2021-09-20

## [7.4.56] - 2021-09-09

## [7.4.55] - 2021-09-09

- [Changed] [Filestore] reworked browser to use JSON api and improve performance

## [7.4.53] - 2021-08-31

- [Fixed] Version of nio4r gem conflicts with AWS Elastic Beanstalk

## [7.4.52] - 2021-08-31

## [7.4.51] - 2021-08-26

- [Changed][filestore] Improvement to filestore browse performance with many files

## [7.4.51] - 2021-08-26

## [7.4.50] - 2021-08-23

## [7.4.49] - 2021-08-18

## [7.4.48] - 2021-08-18

## [7.4.47] - 2021-08-17

## [7.4.46] - 2021-08-17

## [7.4.45] - 2021-08-12

## [7.4.44] - 2021-08-10

## [7.4.43] - 2021-08-10

## [7.4.42] - 2021-08-09

## [7.4.41] - 2021-07-27

## [7.4.40] - 2021-07-26

## [7.4.39] - 2021-07-26

## [7.4.38] - 2021-07-23

## [7.4.37] - 2021-07-22

## [7.4.36] - 2021-07-21

## [7.4.35] - 2021-07-20

## [7.4.34] - 2021-07-20

## [7.4.33] - 2021-07-20

## [7.4.32] - 2021-07-20

## [7.4.31] - 2021-07-19

## [7.4.30] - 2021-07-19

## [7.4.28] - 2021-07-15

## [7.4.27] - 2021-07-14

## [7.4.26] - 2021-07-12

## [7.4.25] - 2021-07-07

## [7.4.24] - 2021-06-22

## [7.4.23] - 2021-06-14

## [7.4.22] - 2021-06-14

## [7.4.21] - 2021-06-14

## [7.4.20] - 2021-06-11

## [7.4.19] - 2021-05-27

## [7.4.18] - 2021-05-27

- [Changed] session storage from cookie based to ActiveRecord. Requires a DB migration to create the new ml_app.sessions table.

  Version 7.4.17 tested and performed vulnerability scans against the new session storage to validate it.

## [7.4.17] - 2021-05-27

## [7.4.17] - 2021-05-27

## [7.4.16] - 2021-05-24

## [7.4.14] - 2021-05-20

## [7.4.13] - 2021-05-20

## [7.4.12] - 2021-05-19

## [7.4.11] - 2021-05-19

## [7.4.10] - 2021-05-19

## [7.4.9] - 2021-05-19

## [7.4.8] - 2021-05-19

## [7.4.7] - 2021-05-19

## [7.4.6] - 2021-05-19

## [7.4.5] - 2021-05-18

## [7.4.4] - 2021-05-18

## [7.4.3] - 2021-05-18

## [7.4.2] - 2021-05-17

## [7.4.1] - 2021-05-17

[Changed] Ruby version to move to Amazon Linux 2

## [7.3.228] - 2021-05-17

## [7.3.227] - 2021-05-14

## [7.3.226] - 2021-05-14

## [7.3.225] - 2021-05-14

## [7.3.224] - 2021-05-14

## [7.3.223] - 2021-05-07

## [7.3.222] - 2021-05-06

## [7.3.221] - 2021-05-05

## [7.3.220] - 2021-05-04

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
