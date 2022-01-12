# Changelog for ReStructure

This file documents notable changes to the ReStructure project.

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

## [8.0.26] - 2022-01-12

<<<<<<< HEAD
### Transferred from Viva @8.0.39

- [Added] user self-registration, email confirmation and password reset
- [Changed] release script to allow clean container to be requested
- [Changed] change_user_roles trigger to allow app_type to be specified
- [Changed] ability to specify multiple checkboxes in report select items
- [Changed] css for mobile responsiveness, css vars and app styles
- [Changed] document library to correctly link to source repository
- [Changed] admin scripts to improve server configuration
- [Fixed] issue with active app types when specified with env var, since it returned an array not a scope
=======
>>>>>>> 7bb775e47dd7b68b06b74aa1f62548785c7fc677

## [8.0.25] - 2021-12-20

- [Bumped] version

## [8.0.24] - 2021-12-20

### Transfer from Harvard @7.4.94 - 2021-12-16

- [Added] scripted job script for OCR
- [Added] logic to avoid too many refreshes on browser
- [Added] PDF and office doc search (within a single document) in secure view
- [Changed] scripted job for better job feedback and documentation
- [Changed] activity log documentation to improve filestore information
- [Changed] report list functionality to results list view
- [Fixed] embedded items not updating in activity logs, causing entered data to be lost
- [Fixed] multiple bugs

### Cherrypicked from Project Viva @8.0.30 - 2021-12-07

- [Fixed] scrolling issue with report result lists

## [8.0.24] - 2021-12-20


## [8.0.23] - 2021-12-03

### Transfer from Harvard @7.4.90 - 2021-12-03

- [Added] restrict access to standalone pages / dashboards with user access controls
- [Fixed] rspec issues
- [Added] configure an alt_column_header for reports
- [Added] allow substitutions in report descriptions and dashboard block headers
- [Added] substitution add*edit_button*
- [Added] disable dynamic definition versions based on app setting
- [Added] hiding of dashboards in list
- [Added] menu / title setting for dashboards (and reports)
- [Fixed] substitutions in forms with no master
- [Fixed] YAML/JSON field viewing and editing
- [Changed] app-type import to prevent disabling user access controls if no config for valid_user_access_controls appear in the uploaded file
- [Changed] big select updated to allow filters and work with dynamic models
- [Changed] editable report lists can work without master_id
- [Added] better handling of report results list with full set of column types from the table
- [Added] report edit and criteria select fields to use models more effectively and provide grouping
- [Fixed] migrations with references that don't produce views

## [8.0.22] - 2021-11-22

- [Added] changes to allow report record edit and create to work with arbitrary models
- [Added] report view*as option to show results as a \_transposed_table*
- [Added] handling of multi*editable* field type configs for lists and choices in forms
- [Added] column option for "choice_label" and ensure it works for all types of display and editing
- [Fixed] multiple bugfixes related to report criteria configuration and select_from_model
- [Fixed] report edit forms and results format and submit dates correctly
- [Fixed] form, credential and trigger bugs
- [Changed] updated to latest gems
- [Fixed] bugfixes

### Transfer from Harvard @7.4.71.1 - 2021-11-15

- [Added] column option for "choice_label" and ensure it works for all types of display and editing
- [Fixed] report edit forms and results format and submit dates correctly
- [Fixed] form, credential and trigger bugs

## [8.0.21] - 2021-11-11

## [8.0.21] - 2021-11-11

## [8.0.20] - 2021-11-11

### Transfer from Harvard @7.4.72 - 2021-11-10

- [Added] Report view_option for show_all_booleans_as_checkboxed
- [Added] use_def_version_time as an optional field to dynamic models to force definition version use for an instance
- [Added] \_constants to extra options dynamic configuration
- [Changed] Model block fields in view mode provide better checkboxes, radios and data/time handling

### Transfer from Harvard @7.4.71 - 2021-11-09

- [Added] Redcap now sets up dynamic model field configurations to display captions, labels and correct field types in edit and view modes
- [Added] Report results options added **embedded_block** to show dynamic models as forms from report resutls
- [Added] Contributor field to data dictionary variable records, to accompany target field.
- [Fixed] Template retrieval and post processing templates
- [Changed] Report results table significantly refactored

## [8.0.19] - 2021-11-10

## [8.0.18] - 2021-11-01

- [Added] Add support for Redcap repeating instruments

## Transfer from Harvard @7.4.70 - 2021-10-31

- [Added] Report criteria field type **select_from_model**
- [Added] Derived variables in dynamic model data dictionary now update from their source variables
- [Added] Enhancements to dynamic model definition panels, especially around data dictionary
- [Fixed] DB comments now updating when a dynamic model is a view
- [Fixed] Ensure views initialize with dynamic models
- [Fixed] Fix issue with times in Redcap leading to constant updating of records
- [Changed] Allow dynamic model updates to add fields where there is no history table
- [Added] Data dictionary handling for dynamic models and model generator
- [Added] Refresh dynamic model configuration from table structure
- [Added] Option to download app-export migrations from server as a zip
- [Added] Automatic creation of reference views based on model reference configs
- [Changed] Version of pg gem to avoid memory leaks
- [Changed] Model reference refactoring
- [Changed] Handling of tracker "alerts" to work without tracker panel being actively displayed
- [Changed] Browser back button in the secure viewer now just closes it
- [Changed] Gems updated, addressing Puma CVE and update to Dalli v3
- [Fixed] Embedded reports autorunning even if "run automatically" was not set

## [8.0.16] - 2021-10-06

- [Added] Model references disabled when to_record is disabled
- [Changed] Study Info app to provide a better authoring experience
- [Changed] processing scripts to allow for app-specfic scripts to be loaded
- [Changed] [Filestore] reworked browser to use JSON api and improve performance
- [Fixed] [Filestore] loop related to unzipping when .z0n parts are missing
- [Fixed] Calculation around boolean fields

## [8.0.15] - 2021-09-03

- [Changed] Docs library to allow links to work within source (and github) as well as in app

## [8.0.14] - 2021-08-23

## [8.0.13] - 2021-08-23

## [8.0.12] - 2021-08-22

## [8.0.11] - 2021-08-12

## [8.0.7] - 2021-01-11

- [Added] Report list view
- [Added] Brand updates (logo)
- [Added] Scripted jobs functionality in filestore pipelines
- [Added] Standalone pages in layouts include web page styled views and file folders
- [Added] improved migration generation and create_or_update migrations generated on app type export
- [Added] External identifiers now use option configurations to apply dynamic definitions to fields and forms
- [Added] improved DB table and field comments, automatically generated from captions and labels
- [Added] activity_selector reference option
- [Changed] app type refactoring and item flag name export / import
- [Changed] item flag (name) improvements to guard against external data errors
- [Changed] moved app configs and migrations to separate repo (<https://github.com/consected/restructure-apps>)
- [Changed] improved image previewing and icons
- [Changed] bugfixes in editable report forms and model reference edit buttons
- [Changed] model reference handling in views
- [Changed] Activity Log admin edit form to provide more information about the current definition
- [Fixed] many fixes

## [8.0.2] - 2020-11-18

- [Added] Role, user access controls and app configuration caching
- [Added] Table comment from default label and captions as field comments
- [Added] Option configs for external identifiers
- [Changed] Versioned template fixes
- [Changed] Time only substitution formatter option
- [Changed] Activity log and dynamic model options editor info
- [Changed] Ensure only correct creatable items appear in panel buttons

## [8.0.1] - 2020-11-12

- [Added] source code for baseline release of the ReStructure project
