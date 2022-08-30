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

## Unreleased

- [Added] show_if generation from Redcap branching logic
- [Added] jasmine-browser-runner to replace old gem and support script app-scripts/jasmine-serve.sh
- [Added] ability to force update of a redcap dynamic model
- [Added] Redcap pull generation of array summary fields for multiple choice checkboxes
- [Added] multilevel functionality to report trees

## [8.0.96] - 2022-08-19

- [Testing] bootsnap
- [Added] password regex option and refactored entropy results
- [Added] disabling of 2FA for user and admin independently
- [Changed] new and edit password forms for usability
- [Fixed] sandbox of iframes (reports and message notifications) to allow popups from links

## [8.0.95] - 2022-08-15

Attempting build to fix mini_portile2 issue again

## [8.0.94] - 2022-08-15

Attempting build to fix mini_portile2 issue

## [8.0.93] - 2022-08-15

- Rebuilt with clean build container

## [8.0.91] - 2022-08-15

- Bumped version
- Rebuild to fix missing gem mini_portile from vendor/cache

## [8.0.89] - 2022-08-15

- [Added] tree view option for reports
- [Added] ui templates for messages in change and forgot password form
- [Fixed] field types not being passed to UI templates for standard subject types

### Transfer from ReStructure 8.0.37 - 2022-08-15

- [Added] ui templates for messages in change and forgot password form
- [Fixed] field types not being passed to UI templates for standard subject types
- [Changed] login issues help for self registration
- [Added] is-(not-?)embedded-report class to report criteria and results blocks
- [Changed] report list checkboxes so the last item in the list can be removed
- [Changed] links to reports in lists to use name rather than id
- [Changed] reporting of redcap stored record requests to give counts rather than list of items
- [Fixed] scrolling on go_to_master save action
- [Fixed] inability to download files in secure viewer when opened from a link outside a filestore browser
- [Fixed] bug getting random value from uninitialized handlebars helper state
- [Fixed] mailto links
- [Fixed] open-in-sidebar from study info pages
- [Added] overflow storage to handle local_storage quota
- [Added] ability for report page to force to run with a param ?force_run=true
- [Added] open-embedded-report hash options for URLs in content
- [Added] edit_as: general_selection: to override standard general selection definition for a field to use
- [Added] page_embedded_block to study info
- [Fixed] issue with redcap admin NFS container
- [Added] ui templates for messages in change and forgot password form
- [Fixed] field types not being passed to UI templates for standard subject types

## [8.0.88] - 2022-07-05

- [Added] other_user_is_creator from reference option

## [8.0.86] - 2022-07-04

- [Fixed] context issue with edit form captions

## [8.0.85] - 2022-07-04

- [Added] reference definition without_reference: outside_master
- [Fixed] passing user_preference to front end

## [8.0.84] - 2022-06-30

- [Added] ability for standalone pages to be loaded in the help sidebar
- [Added] escaping for curly brackets in substitutions
- [Changed] documentation for optional MFA and added substitution info

## [8.0.83] - 2022-06-29

- [Added] invitation code to registration
- [Added] view_original_case field option to prevent the UI capitalizing downcased fields
- [Fixed] help sidebar in standalone help pages

## [8.0.82] - 2022-06-29

- [Added] first login sidebar popup

## [8.0.81] - 2022-06-29

- [Added] notifications option to user menu and updated help with notifications page
- [Added] help link handling in study info pages
- [Changed] substitutions to allow glyphicons and notifications_from_email address

## [8.0.80] - 2022-06-28

- [Fixed] issue with nested ordered lists in markdown editor
- [Fixed] hiding modal on submitting embedded form & no_report_scroll not enabling full page scroll
- [Fixed] search doc with download/in route form - plus refactored to DRY code

## [8.0.79] - 2022-06-27

- [Added] message template UI blocks for registration forms and user preferences
- [Added] admin documentation for message templates
- [Added] caption before references with extra log types
- [Added] on_master_id as embedded_report extension
- [Changed] expand_reference action to scroll to result
- [Fixed] issue where activity log panels don't get fully scrolled to

## [8.0.78] - 2022-06-23

- [Fixed] issue where report list updates fail if user only has view_report_not_list access
- [Updated] expand_reference documentation

## [8.0.76] - 2022-060-22

- [Added] preprocessing to CSV imports for array fields
- [Added] sample use of API in Ruby scripts
- [Added] study info content migrator using api
- [Changed] to handle select_record fields not associated with master and better documentation
- [Changed] allowable fields in import CSV to allow "disabled"
- [Fixed] issue where incorrect page layout nav configuration breaks UI completely

## [8.0.75] - 2022-06-14

### Transfer from ReStructure 8.0.34 - 2022-06-14

- [Added] new_caption option
- [Added] returning JSON data related to created_by_user for current instance and master
- [Added] prevent-reload-on-reference-save class to prevent an updated or created reference forcing the container block to refresh
- [Added] show-in-modal class for links, allowing a confirmation mechanism for dangerous actions
- [Changed] handling of closing an embedded report modal to only refresh if the container block has a class allow-refresh-item-on-modal-close
- [Changed] error handling related to selection configs in selector_with_config_overrides, so there is enough information to diagnose an issue
- [Fixed] prevent_disable on references when pluralized
- [Fixed] handling of created_by_user reference in dynamic migrations
- [Fixed] select from record configs again
- [Fixed] incorrect titleization of substitutions within UI

### Transfer from ReStructure 8.0.31 - 2022-06-01

- [Fixed] issue related to definition loading and select from record configs

## [8.0.74] - 2022-05-31

- [Added] admin capabilities to allow admins to be restricted in what they can administer
- [Added] responsive styling to secure viewer
- [Added] infinite scrolling to secure viewer
- [Added] option for nfs_store: view_options: show_file_links_as: path to enable path URI in filestore browser
- [Added] path based access to container files, and a link provided in stored file and archived file forms
- [Added] consistent secondary key handling for activity logs

## [8.0.73] - 2022-05-25

- [Added] download of files using a download_path param
- [Fixed] failure attempting to edit external id

## [8.0.72] - 2022-05-24

- [Added] showing select*from*... values based on live data and master associations, not just dynamic definitions
- [Added] global app definition of nav links, and ability for icon to be used without a label
- [Fixed] date and time formatting in reports presented as lists

## [8.0.71] - 2022-05-23

- [Added] show_as iframe for report cell and fixed tags handling
- [Fixed] handling of always_use_this_for_access_control, save trigger success and skip_if_exists

## [8.0.70] - 2022-05-18

- [Added] filestore browser to appear in edit forms, if view_as: edit: filestore is set
- [Changed] if block substitutions to allow for multiline text
- [Fixed] calc action to use conditions consistently

## [8.0.69] - 2022-05-17

- [Fixed] issue with if block substitutions
- [Fixed] bug with using document secure viewer on second load of report results

## [8.0.68] - 2022-05-17

- [Added] if block substitions

## [8.0.67] - 2022-05-17

- [Fixed] migrations related to reference views

## [8.0.66] - 2022-05-17

- [Fixed] css for hiding empty captions
- [Fixed] issue adding new dynamic models

## [8.0.65] - 2022-05-16

- [Fixed] recursive calling of save trigger within update_this and pull_external_data
- [Fixed] references: showable_if: calculation causing infinite recursion

## [8.0.64] - 2022-05-16

### Transfer from ReStructure 8.0.30 - 2022-05-16

- [Changed] de/re-identification job failure handling for reliability
- [Changed] dynamic definition code to DRY common usages

## [8.0.63] - 2022-05-13

- [Changed] rules so master_id can be provided as a regular field, not a foreign key (for Redcap data for example)
- [Changed] handling of redcap pull to ignore excess fields in dynamic model
- [Fixed] dynamic migrations adding master_id foreign key field after creation

## [8.0.62] - 2022-05-11

- [Fixed] show_if issues with object fields and referenced dynamic_models

## [8.0.61] - 2022-05-11

- [Added] field_options: field_name: preset_value: option
- [Added] direct embed ability through options or field definitions
- [Added] viewing / editing of direct embedded item within a stored file
- [Added] pull_external_data save trigger
- [Added] full markdown support for master list header title
- [Added] change_user_roles option for_user to specify non-current user, and allow lookup of role names with calc reference
- [Changed] parallel tests script and specs for reliability
- [Fixed] curly substitutions in javascript to traverse full dotted path
- [Fixed] substitutions for markdown to HTML incorrectly identifying HTML documents
- [Fixed] datepicker being hidden by modal view
- [Fixed] issue with caching of user roles and access controls not clearing when new role added

## [8.0.60] - 2022-04-22

- [Changed] embedded_block to allow formatting of link and allow models related to a master to edit
- [Added] tag select for records from tables / dynamic models
- [Fixed] issue with created_by_user_id

## [8.0.59] - 2022-04-21

- [Changed] gemfile to include puma in all environments, to allow latest version to be installed on beanstalk
- [Changed] styling of user profile panel
- [Fixed] issue with view_options in model references

## [8.0.58] - 2022-04-12

- [Added] view_css support to regular panels
- [Added] force_not_valid option in create/update_reference and update_this
- [Added] ability for save_action to return the first result that matches an if condition
- [Fixed] Fixed issue with simple true in show_if and save_action
- [Fixed] specs for stubbing and activity log definitions
- [Fixed] issues with dynamic reloading
- [Updated] puma to 5.6.4 - Procfile for AWS Beanstalk created during deployment must start the web: entry with bundle exec to use the bundled version

## [8.0.57] - 2022-03-31

Interim release for testing only

## [8.0.56] - 2022-03-30

Interim release for testing only

## [8.0.55] - 2022-03-28

- [Added] users as a table to calculate against in \*\_if evaluations
- [Added] save_action expand_reference
- [Added] media queries to view css options
- [Added] activity log master and item associations for extra log types, allowing for substitutions against a specific activity
- [Added] defined_selector options to reports criteria to allow easy selector configuration based on central and model configurations
- [Added] 'never' option to always*embed*\*reference
- [Added] ability for an existing admin to add a new admin account if appropriate server setting allows
- [Fixed] limited_access_control using association master_created_by_user
- [Fixed] issue loading images when window not focused

## [8.0.54] - 2022-03-16

Interim release for testing only

## [8.0.53] - 2022-03-15

Interim release for testing only

## [8.0.52] - 2022-03-08

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

## [8.0.51] - 2022-03-03

Interim release for testing only

## [8.0.50] - 2022-03-03

Interim release for testing only

## [8.0.49] - 2022-03-02

Interim release for testing only

## [8.0.48] - 2022-03-01

Interim release for testing only

## [8.0.46] - 2022-02-24

Interim release for testing only

## [8.0.45] - 2022-02-24

Interim release for testing only

## [8.0.44] - 2022-02-24

Interim release for testing only

## [8.0.43] - 2022-02-23

Interim release for testing only

## [8.0.41] - 2022-02-11

### Transfer from ReStructure 8.0.27 - 2022-02-10

- [Fixed] pregenerated and non-editable external identifier fields not to show
- [Changed] export of app-export migrations to go to a single app directory, not each schema directory
- [Added] app admin navigation for current app
- [Fixed] Beanstalk scripts
- [Updated] restart script to allow full EB restart of all app servers
- [Added] app type components page for easy viewing and navigation around an app
- [Added] ability to filter admin resources by id, ids or resource name

## [8.0.40] - 2022-01-24

- [Added] ability to show embedded block from an embedded report in a second modal

## [8.0.39] - 2022-01-11

- [Fixed] issue with active app types when specified with env var, since it returned an array not a scope

## [8.0.38] - 2022-01-11

- [Updated] release script to allow clean container to be requested
- [Updated] change_user_roles trigger to allow app_type to be specified

## [8.0.37] - 2022-01-11

- [Added] ability to specify multiple checkboxes in report select items
- [Fixed] bug by supressing notification when the admins change their passwords
- [Updated] css for mobile responsiveness, css vars and app styles
- [Updated] document library to correctly link to source repository
- [Updated] admin scripts to improve server configuration

## [8.0.35] - 2022-01-06

- [Bumped] version

## [8.0.33] - 2022-01-06

- [Added] user self-registration, email confirmation and password reset

### Transfer from ReStructure 8.0.24 - 2021-12-20

- [Added] scripted job script for OCR
- [Added] logic to avoid too many refreshes on browser
- [Added] PDF and office doc search (within a single document) in secure view
- [Changed] scripted job for better job feedback and documentation
- [Changed] activity log documentation to improve filestore information
- [Changed] report list functionality to results list view
- [Fixed] embedded items not updating in activity logs, causing entered data to be lost
- [Fixed] multiple bugs

## [8.0.32] - 2021-12-14

- [Added] demo release

## [8.0.30] - 2021-12-07

- [Fixed] scrolling issue with report result lists

## [8.0.29] - 2021-12-07

- [Fixed] report criteria select_from_model defaults

## [8.0.28] - 2021-12-03

- [Changed] rebuild

## [8.0.27] - 2021-12-03

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

## [8.0.26] - 2021-11-24

- [Added] better handling of report results list with full set of column types from the table
- [Added] report edit and criteria select fields to use models more effectively and provide grouping
- [Fixed] migrations with references that don't produce views

## [8.0.25] - 2021-11-22

- [Added] changes to allow report record edit and create to work with arbitrary models
- [Added] report view*as option to show results as a \_transposed_table*
- [Added] handling of multi*editable* field type configs for lists and choices in forms
- [Added] column option for "choice_label" and ensure it works for all types of display and editing
- [Fixed] multiple bugfixes related to report criteria configuration and select_from_model
- [Fixed] report edit forms and results format and submit dates correctly
- [Fixed] form, credential and trigger bugs
- [Changed] updated to latest gems
- [Fixed] bugfixes

## [8.0.24] - 2021-11-16

- Bump version

## [8.0.23] - 2021-11-16

## [8.0.22] - 2021-11-15

### Transfer from Harvard @7.4.71.1 - 2021-11-15

- [Added] column option for "choice_label" and ensure it works for all types of display and editing
- [Fixed] report edit forms and results format and submit dates correctly
- [Fixed] form, credential and trigger bugs
- [Fixed] - bugfixes

## [8.0.21] - 2021-11-11

- [Fixed] production environment use of encryption salt

## [8.0.20] - 2021-11-10

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

## [8.0.19] - 2021-11-01

- [Added] Documentation for a private repository fork

NOTE: this build is largely to test the new private repository is complete and can be built

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
