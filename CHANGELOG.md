# Changelog for ReStructure

This file documents notable changes to the ReStructure project.

The format of this file is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

In short this means that version numbers, visible here and on the login page of the app match, and have a predictable format indicating how much change from the previous version has occurred.

The [Unreleased](#unreleased) section collects notes for unreleased changes and features, until they are absorbed into a formal release in a version number tagged section below.

Note that not every tagged version may be suitable for production use. A Github release will be created for any release tested in production, and may be marked below with the tag [Release].

Since [version 8.4.0](#840---2024-01-10) the convention is that releases made within forked repositories should be up-versioned with a patch release, *x.y.z+1*. When changes are incorporated back into the primary repo [consected/restructure](https://github.com/consected/restructure) a new minor release will be created, *x.y+1,0*.

## [8.2.66] - 2023-09-05

### From FPHS - 2024-11-14

[Fixed] failing versions list when creating a new dynamic model

### From FPHS - PR #413 - 2024-11-13

[Fixed] issues from merging recent PRs

### From FPHS - PR #412 - 2024-11-04

- [Fixed] CVE-2024-8796 for 2FA secret lengths and updated Devise to latest version
- [Updated] brakeman whitelist for Rails
- [Updated] gems to resolve security alerts in bundle-audit scan

### From FPHS - PR #411 - 2024-10-31

- [Fixed] spec based on schema name validation
- [Fixed] error setting redcap schema name intermittently

### From FPHS - PR #410 - 2024-10-17

- [Added] use of "chosen" drop down for admin forms to aid faster configurations
- [Added] ignore_no_recipients as an option to notify sms
- [Changed] presentation of fixed_... fields to avoid them being accidentally selected
- [Added] admin filter on server url for Redcap projects
- [Added] information to help with debugging common create_reference configuration error
- [Added] config_trigger.on_define.embed options to allow_reconfiguration (default no) and prefix_config_libraries
- [Added] format check for dialog_before configurations and check message template exists
- [Added] a page layout view option for default_expander to present activity log blocks as "shrunk" by default

### From FPHS - PR #409 - 2024-10-31

- [Fixed] issue with presets and current admin sample
- [Changed] handling of admin sample form to show dialog names, field names, form names of embedded forms

### From FPHS - PR #408 - 2024-10-29

- [Fixed] specs for browser testing
- [Fixed] specs for redcap model generation
- [Fixed] UI issues related to templates loading
- [Fixed] spec to use correct item
- [Fixed] test if embedded item in config setup
- [Fixed] documentation of and_latest_matches
- [Added] feedback of client errors in dev/test
- [Fixed] styling of tracker new and edit forms
- [Fixed] display of filestore block in edit forms
- [Fixed] handling of UI template loading to ensure blocks load correctly or report an error if not
- [Fixed] failing specs due to missing attribute on standard models
- [Fixed] overflowing display of filter selectors in activity log panels
- [Fixed] time fields don't accept default - fixes #391
- [Fixed] broken markup in dialogs
- [Changed] small admin presentation issues
- [Changed] css and typo
- [Fixed] issue with app_type import failing where underlying tables don't exist or aren't created because the app or models are disabled
- [Fixed] handling of force_not_valid feeding through to embedded_item
- [Fixed] unnecessary exception
- [Fixed] markdown notes fields in esignatures
- [Fixed] bad setup of dev filestore
- [Fixed] handling of create_default.user_access_control to avoid breaking setup if the control already exists with a different access
- [Fixed] showing new index when copying an admin item

### From FPHS - PR #407 - 2024-10-10

- [Updated] Ruby to 3.2.5 and updated gems

### From FPHS - PR #406 - 2024-10-17

- [Added] versions list to dynamic model admin panel
- [Added] a check on saving a new version of an admin configuration, to ensure saved changes in another tab aren't overwritten - closes #387

### From FPHS - PR #405 - 2024-10-23

- [Changed] display of components to avoid duplication
- [Changed] presentation of admin panel component selection panel to group by category
- [Changed] formatting of admin panel component list

### From FPHS - PR #404 - 2024-10-17

- [Added] new "calculate" options for count_not_null and mean
- [Added] and_latest_matches to if conditions to check if one value is the latest of a possible set

### From FPHS - PR #403 - 2024-10-17

- [Fixed] occasional error due to presets being loaded unnecessarily
- [Added] ability for create/update reference and preset_fields to use with_results multiple times (array) to pull from different sources
- [Added] preset_fields option to preset values to a mass of fields on initialization of new items, or before creating a reference.
- [Fixed] issue with preset_value being set within a referenced item

### From FPHS - PR #402 - 2024-10-21

- [Fixed] label resizing for show_if changes
- [Fixed] current_mode not being passed to embedded_item for show_if
- [Fixed] issue with show_if checking time field conditions. Changes are now triggered.
- [Fixed] issue with conditionally showing dialog placeholders in admin view
- [Added] substitution comparisons in show_if rules
- [Fixed] broken show_if

### From FPHS - PR #401 - 2024-10-24

- [Changed] handling of #is and #if substitutions to make it less sensitive to extra spaces
- [Fixed] matching of {{#is...}} operators
- [Fixed] substitutions in {{#is}} to handle integers correctly
- [Added] comparison operators to {{#is}} substitutions
- [Added] {{else if}} and {{else is}} to substitutions
- [Added] `{{else if}}` to substitutions
- [Added] age to subject handler and allow it to be substituted with `{{player_info.subject_age}}` or through generated JSON
- [Added] tag value retrieval on right hand side of {{#is...}} comparisons
- [Added] {{#is ...}} handling to dialogs and captions in show mode
- [Fixed] #is #else handling

### From FPHS - PR #400 - 2024-10-28

[Changed] loading of routes to load only a single time after regenerating a model
[Fixed] issue preventing routes being regenerated

### From FPHS - [8.8.11] - PR #399 - 2024-09-12

- [Changed] sorting of external identifier columns in master panel
- [Added] logger info when an item is not creatable
- [Fixed] broken chart size
- [Added] CONTENTS_LIST capability to help sidebar. Specify a link `[CONTENTS_LIST](h2)` to list h2 tags in place of the link
- [Fixed] content type for create shortlink in substitutions
- [Fixed] dynamic definition option `embed: <string>` doesn't work - fixes #388

### From FPHS - [8.8.10] - PR #398 - 2024-09-11

- [Fixed] message notifications sending SMS messages with HTML markup
- [Added] {{#is ...}} to substitutions - closes #222
- [Fixed] handling of report editing when creating a new row when using {{table_name}} substitution
- [Fixed] sidebar viewing of info pages
- [Fixed] delayed_job startup to avoid breaking memcached IO
- [Added] sidebar viewing and standalone page viewing of info-pages
- [Added] admin panel drop down components list
- [Added] better information about save trigger current user missing
- [Added] "# @library" within config libraries to allow import of config libraries that rely on others
- [Added] extra information to help debug iterator issues in save trigger
- [Fixed] formatting issue in dynamic model details panel

### From FPHS - [8.8.9] - 2024-09-04

- [Changed] handling of create_reference with embedded_item to ensure save triggers can reference the new embedded item
- [Fixed] error message
- [Fixed] to ensure calculations get the correct type of embedded item
- [Fixed] batch_trigger user and app_type settings to use app_type if specified

### From FPHS - [8.8.8] - 2024-09-03

- [Changed] logging to use short backtrace
- [Fixed] redcap storage issue with blank survey identifiers

### From FPHS - [8.8.7] - 2024-09-03

- [Added] skip_store_if_no_survey_identifier option to redcap projects
- [Changed] handling of report record editing to correctly handle columns not editable or not configured to edit
- [Fixed] editing a report table item (external identifier model) and adding a master id fails - fixes #376
- [Fixed] Dynamic::ImplementationHandler#force_preset_values should only operate on model attributes, not every preset_value definition - fixes #380
- [Fixed] pattern documentation
- [Fixed] show if comparisons for Redcap when the condition is based on a boolean field - fixes #381

### From FPHS - [8.8.6] - 2024-08-29

- [Added] checks for blank and incorrect schemas, and associated automatic initialization of the value
- [Fixed] issues with local variables not existing

### From FPHS - [8.8.5] - 2024-08-28

- [Added] new check in Redcap project to ensure user has access to the associated external id table, if specified
- [Added] ability for report edit table name and fields to be specified as {{table_name}} and {{table_fields}} to allow editing of arbitrary tables in the generic report
- [Added] RedcapJobUserEmail setting to be viewed in server info
- [Fixed] user creating an external identifier with additional fields loses their value - fixes #307
- [Changed] external identifier details panel to add "search data" link - especially helpful if the user can edit the results for example to add other field entries to external id records
- [Changed] specification of Redcap project run_jobs_in_app_type to only use the current user's app type if the configuration is not specified (it previously ignored a specified app not being found)
- [Added] exceptions to make it clear if a master id was not found through an external id for various reasons
- [Fixed] incorrect error message

### From FPHS - [8.8.4] - 2024-08-27

- [Added] save trigger create_reference, update_reference and update_this to accept embedded_item hash to create or update the appropriate item automatically

### From FPHS - [8.8.3] - 2024-08-22

- [Fixed] viewing a master record with category of redcap dynamic models (which show in a default panel) loads all entries in the database - fixes #370
- [Added] redcap project option set_master_id_using_association, which adds a master_id to the underlying table and sets it automatically from the external id association - closes #369
- [Added] ability for redcap project associate_master_through_external_identifer to match on external identifiers with integer external ids, by adding an integer redcap_survey_identifier_id field to the dynamic model
- [Added] better information around missing fields and mismatched in the redcap project
- [Added] the ability to retrieve the latest redcap configuration within the redcap project, so field configurations can be correctly validated
- [Added] redcap project run_jobs_as_user and run_jobs_as_app_type options to ensure background jobs run consistently
- [Fixed] dynamic models with foreign keys breaking the admin sample form view
- [Fixed] Redcap project reconfigures dynamic model with new one if the category of the DM has changed - fixes #365
- [Added] redcap project admin option associate_master_through_external_identifer: [external identifier] to automatically allow connection of redcap_survey_identifier to a master record through a matching external id - closes #369
- [Added] estimated record count and new config checks to redcap project admin details panel
- [Added] checking of tracker protocol updates in dynamic definitions details panels
- [Added] _configurations.foreign_key_through_external_id to associate a dynamic model back to a master record through an external id field, rather than master_id or crosswalk attribute.

### From FPHS - [8.8.2] - 2024-08-12

- [Build] FPHS version

### From FPHS [8.8.1] - PR 363

- [Added] new options and date reporting to script

### From FPHS - PR 362

- [Added] ability to only show listed tabs using `<uri>?only_tabs[<resource_name>]=true&...` or `?only_tabs[categories]=true&...`
- [Added] master panel options to page layouts to allow filtering of resource items by configured filter, or by page URL query params
- [Added] master panel options to "show for single master only" and "show for multi master only" so different panels can be shown for different UI states
- [Fixed] caching of apps available to users
- [Fixed] masters index history being pushed if the aim is to not prevent a reload
- [Fixed] available app type lookup for a user - role names where only being checked in the current app, not for the app being tested
- [Added] cache to admin index page to speed things up
- [Fixed] admin email lookup in admin info icons

### From FPHS - PR 361

- [Changed] loading of associated model definitions, improving performance and presentation
- [Added] definition_resources as an alias resource name for consistent substitutions and conditions
- [Added] config_trigger.create_configs option to create related configurations using app import format
- [Added] config_trigger option to make building activity log processes easier
- [Added] calculated condition to calculate using a function such as sum, min, max - closes #308
- [Added] estimated record count to dynamic definitions - closes #265
- [Added] with_result to create/update... save triggers
- [Added] embedded_item option to conditional calculations
- [Added] ids_referencing condition and ability to get return_all_results from a condition
- [Fixed] condition negate and add include? condition
- [Fixed] incorrect handling of save trigger on_save option as an array when on_create is a hash (or vice versa)
- [Added] ability for extra_log_type to be used in creatable_if condition
- [Added] handling of invalid_error_message at top of an all/any/not... block to prevent invididual errors being recorded, allowing them all to roll up to a single result
- [Fixed] tag element array index retrieval
- [Fixed] handling of implementation class setup to avoid preset value definitions breaking the implementation
- [Added] view_with_formats to field_options, allowing a series of tag formatters to be applied when viewing the field
- [Fixed] embedded items not setting preset_value
- [Fixed] address view handler with no country field
- [Added] save trigger results for created and updated results
- [Fixed] use of view_options.header caption configuration in external id definitions
- [Added] embed definitions into the activity log details panel - fixes #19
- [Added] "in?" to the simple conditions that can be tested in non-query conditions
- [Added] non-query condition elements to specify last as well as first in the traversal of the dot separated list
- [Added] "if:" option to save trigger "each:" to avoid having to check the same "if" for every trigger
- [Added] ability to define external id configurations for uniqueness_fields, can_change_master and fix saving from a add item report
- [Changed] calling #enabled to #active for consistency
- [Fixed] curly substitutions to allow .last to appear on the end of a requested element

### From FPHS - PR 360

- [Added] iteration through save triggers based on an array of values - closes #348
- [Added] save triggers definition as a list of triggers instead of a hash - closes #347
- [Added] updated_items element to save_trigger_results for update_reference trigger - fixes #345
- [Added] save trigger create_reference in a specific record - fixes #346

### From FPHS - PR 359

- [Added] significant cache and user access lookup changes to improve performance
- [Added] preloading to reduce n+1 lookups
- [Added] eager loading of various models to improve performance and reduce database hits
- [Changed] cache keys
- [Changed] handling and reporting of adding tracker update protocol events
- [Fixed] broken scope for lookups by name
- [Fixed] specs to avoid common issues
- [Fixed] seed to handle disabled items
- [Fixed] parsing of date times for user preferences
- [Fixed] issue importing new app type
- [Fixed] bad memoization of associated items in app type
- [Fixed] caching of user access controls to avoid storing an ActiveRecord instance
- [Removed] unnecessary TrackerHandler

### From FPHS - PR 358

- [Fixed] password self-reset fails with exception if user is disabled - fixes #342
- [Added] field option for blank_preset_value and allow substitutions in preset_value - fixes #220
- [Fixed] issue in selector cache, where callers were sensitive to attributes with symbol or string keys
- [Changed] parallel tests to ask for sudo early in the process if needed
- [Added] spec for getting master id using MSID in conditions
- [Fixed] dashboard error not being to load report resources
- [Added] definition for multiple save buttons, with show_if control
- [Changed] settings to ensure proper nil results for empty environment variables
- [Added] edit_as options to select_user_with fields
- [Fixed] issue where table comments with apostrophes break the migration with a syntax error. Fixes #331 and #332
- [Changed] logging of job failure notification
- [Fixed] error reporting failed job
- [Changed] cache invalidation to avoid unnecessary requests to clear the cache
- [Fixed] spec to clear cache between requests

### From FPHS - PR 357

- [Added] the http content response to a Redcap job error to aid debugging issues

## [8.7.1] - 2023-09-05

### From Viva - PR 356

- [Added] report handler for sidebar_hash_content_links to ensure these hashed links work correctly
- [Added] protection against multiple report auto runs
- [Added] caption before close button on embedded report modal when list item changed
- [Changed] handling of email address lookups from settings to ensure lower case matching is used
- [Added] configuration checks for admin and user email addresses set by environment variables
- [Changed] the message to users on expiration of an account to avoid confusion if a user can reset their own password
- [Changed] matching of email address for batch user to allow mixed case definition to match the lower case user email address
- [Added] comment clarifying failure to set the OTP, MFA fields

### From Viva - PR 355

- [Added] report results count attribute to markup to allow better styling for no results
- [Fixed] "loading..." message for empty report tree resultsets
- [Changed] style of loading tree report
- [Fixed] auto submission of reports on criteria changed by clarifying use of configuration

### From Viva - PR 354

- [Added] edit_as options to select_user_with fields - allows displayed label and value to be different from email

### From Viva - PR 353

- [Added] reCAPTCHA as an option to protect registration pages
- [Fixed] an unhelpful error message when registering if an empty password was provided

### From Viva - PR 352

- [Changed] display of tree report loading
- [Fixed] tree embedded report when there is a report in the underlying page (embedded in a placeholder for example)
- [Added] report results handler to force all \<pre> elements to be fully expanded
- [Fixed] mailto links breaking in sidebar when content is a portal page
- [Fixed] editor html cleanup losing images and horizonal rule
- [Fixed] tree expander implementations
- [Fixed] report criteria drop down selector filters not loading when default criteria passed through URL

### From Viva - PR 351

- [Fixed] use of Etag headers for caching
- [Changed] browser caching for common scenarios

## [8.6.1] - 2024-03-04

- [Bumped] version
- [Build] with latest changes from contributors
- [Updated] gems to address CVEs
  - CVE-2024-26144
  - CVE-2024-25126
  - CVE-2024-26141
  - CVE-2024-26146
  - CVE-2024-27285

## [8.5.2] - 2024-02-21

### From Viva

- [Added] cleanup of test dynamic models
- [Fixed] parallel test cleanups
- [Fixed] spec setup regression
- [Added] tally of rspec test setups completed in the database for faster testing
- [Fixed] checking of deleted records in tests
- [Fixed] Message notifications sending to a role shows users that have been disabled or are templates or are set to no email - fixes #234
- [Changed] message notifications to show date/time sent using user preference and to make it clear when a message has not been sent yet - fixes #239
- [Added] simpler date time formatting within the user's timezone
- [Fixed] notify save trigger with a list of notifications incorrectly sends the first one to all roles and users - fixes #281

### From Harvard

- [Fixed] add_tracker trigger failing in confusing way if there is no master record to add the tracker to - fixes #260
- [Changed] code to support Ruby 3.2.2
- [Changed] email notification of job failure to link to the job
- [Added] delete failed jobs and find job in admin form
- [Refactored] implementation of job searches and Delayed::Job initialization
- [Bumped] version

## [8.4.9] - 2024-02-13

### From Harvard

- [Fixed] specs with Spring
- [Added] notes about contributing pull requests
- [Fixed] add_tracker trigger failing in confusing way if there is no master record to add the tracker to - fixes #260
- [Updated] gems to address CVE-2024-25062
- [Fixed] background Job failures still not notifying the admin via email - fixes #258
- [Added] splitting to chunks for large files uploaded through API
- [Added] improved handling of chunk uploads to check for and handle failures
- [Fixed] Filestore reporting of chunk upload failures
- [Fixed] error not showing external identifiers in standard master record view

## [8.4.8] - 2024-01-30

- [Fixed] incorrect updated_at date being used in admin panel index lists
- [Added] paging to redcap record storage, improved job logging and link back to job from Redcap admin panel, - fixes #269 #268 #267
- [Changed] (again) handling of JSON and string output for time fields

## [8.4.7] - 2024-01-30

- [Changed] handling of JSON and string output for time fields

## [8.4.6] - 2024-01-29

- [Added] time_ignore_zone substitution formatter

## [8.4.5] - 2024-01-25

- [Fixed] send file to trash not visible if the container was not originally editable - fixes #245
- [Fixed] selecting a file in the filestore browser with a checkbox prevents navigation away from the page - fixes #242
- [Fixed] error not showing external identifiers in standard master record view
- [Added] better reporting of error in spec

## [8.4.4] - 2024-01-16

- [Fixed] conditions not working correctly for nested user: role_name: 'name' - fixes #240

## [8.4.3] - 2024-01-16

- [Added] nfs_store configuration to conditionally enable actions like "send file to trash" - resolves #236
- [Fixed] script to ensure exit if early git actions fail
- [Added] bundle-audit ignore file and entry for devise-two-factor gem
- [Fixed] add_tracker trigger failing in confusing way if there is no master record to add the tracker to - fixes #260
- [Updated] gems to address CVE-2024-25062

## [8.4.5] - 2024-02-01

- [Fixed] background Job failures still not notifying the admin via email - fixes #258

## [8.4.4] - 2024-01-31

- [Added] splitting to chunks for large files uploaded through API
- [Added] improved handling of chunk uploads to check for and handle failures
- [Fixed] Filestore reporting of chunk upload failures

## [8.4.3] - 2024-01-24

- [Fixed] error not showing external identifiers in standard master record view

## [8.4.2] - 2024-01-11

- [Build] FPHS version

## [8.4.1] - 2024-01-11

- [Fixed] bug introduced by configuration of tracker ordering - fixes #232
- [Changed] release to remove all dependence on git-flow
- [Added] new versioning convention details and other README updates

## [8.4.0] - 2024-01-10

- [Bumped] minor version

## [8.2.123] - 2024-01-10

- [Added] upversioning minor version in release process
- [Updated] yarn modules

## [8.2.122] - 2024-01-10

- [Added] feature to allow tracker to sort protocols by latest event date as an alternative to the default, which is to order by configured protocol position - resolves #72
- [Fixed] (hopefully) restarting of delayed_job from the server
- [Added] more information to document conversion error
- [Added] FailureNotificationsToEmail to server settings variable viewer
- [Added] cleanup of app configurations to avoid spaces and nulls leading to duplicate entries
- [Added] current user id as state in the application page script
- [Added] ability to rerun DB seeds from server info
- [Changed] field validation messages to always show as "Entry" rather than a meaningless field name
- [Added] handling of disabled groups in "chosen" drop-downs to hide correctly, especially when using the data-filter-selector option
- [Added] extra checking and logging around Libreoffice, plus kill stuck processes
- [Added] a data-user-roles attribute to body, allowing body[data-user-roles~='underscored_role_name'] to be used in CSS
- [Fixed] issues with model reference data being blank and used for record matching in transfer script
- [Changed] nav links page layout to avoid showing app types not available to the user
- [Fixed] email notifications from and failure notification to email address settings
- [Changed] to remove empty placeholder captions, even if they have just a blank paragraph
- [Fixed] handling of model references in curly substitutions in the front end
- [Changed] API sample for study info transfer to another server
- [Fixed] CSV import form bug
- [Added] configuration check for OTC encoding key
- [Added] make-labels-placeholders to documentation
- [Fixed] integer field to allow negative numbers - fixes CSV import of master id does not allow negative numbers #218
- [Fixed] CSV import not recognizing uploaded file correctly
- [Fixed] duplicate tables appearing in CSV import drop down table list
- [Fixed] mr-expander closing an already expanded item
- [Added] improved control over scrolling, especially in activity logs
- [Fixed] validation error message formatting with nested conditions
- [Fixed] jobs are supposed to send an admin email if they fail - fixes #210
- [Changed] handling of scrolling if the target item was removed from the page
- [Fixed] report new / edited records not showing
- [Changed] error message when a RecordInvalid exception is thrown

## [8.2.121] - 2023-12-21

- [Added] cleanup of app configurations to avoid spaces and nulls leading to duplicate entries
- [Added] current user id as state in the application page script
- [Added] ability to rerun DB seeds from server info
- [Changed] field validation messages to always show as "Entry" rather than a meaningless field name
- [Added] handling of disabled groups in "chosen" drop-downs to hide correctly, especially when using the data-filter-selector option
- [Added] extra checking and logging around Libreoffice, plus kill stuck processes
- [Added] a data-user-roles attribute to body, allowing body[data-user-roles~='underscored_role_name'] to be used in CSS
- [Fixed] issues with model reference data being blank and used for record matching in transfer script
- [Changed] nav links page layout to avoid showing app types not available to the user
- [Fixed] email notifications from and failure notification to email address settings

## [8.2.120] - 2023-12-13

- [Changed] to remove empty placeholder captions, even if they have just a blank paragraph
- [Fixed] handling of model references in curly substitutions in the front end

## [8.2.119] - 2023-12-12

- [Changed] API sample for study info transfer to another server
- [Fixed] CSV import form bug
- [Added] configuration check for OTC encoding key
- [Added] make-labels-placeholders to documentation
- [Fixed] integer field to allow negative numbers - fixes CSV import of master id does not allow negative numbers #218
- [Fixed] CSV import not recognizing uploaded file correctly
- [Fixed] duplicate tables appearing in CSV import drop down table list
- [Fixed] mr-expander closing an already expanded item

## [8.2.118] - 2023-12-04

- [Added] improved control over scrolling, especially in activity logs
- [Fixed] validation error message formatting with nested conditions
- [Fixed] jobs are supposed to send an admin email if they fail - fixes #210

## [8.2.117] - 2023-11-27

- [Changed] handling of scrolling if the target item was removed from the page
- [Fixed] report new / edited records not showing
- [Changed] error message when a RecordInvalid exception is thrown

## [8.2.116] - 2023-11-23

- Bumped version

## [8.2.114] - 2023-11-23

- [Changed] admin panel to add more visible config status and moved admin user actions to main panel
- [Cleanup] exception display
- [Changed] scripts for better error reporting
- [Cleanup] specs
- [Added] confirmed at column to user display
- [Fixed] user resets a password themselves but their account is locked - now we unlock the account - fixes #116
- [Fixed] user has not been assigned any accessible app types, they receive no message on logging in and just return to the login page - fixes #204
- [Changed] self registration of users allowed and an admin creates a user, auto confirmation automatically set to avoid unnecessary confirmation email - fixes  #205
- [Fixed] Admin resets password for a user with "do not email" set causes an exception - fixes #202
- [Fixed] admin with capability "redcap" can see Redcap projects on the admin panel, but is not authorized to click into it - fixes #203
- [Added] more information to make the upload scripts more usable
- [Added] full API script to upload files from a directory to different containers - fixes #197
- [Changed] 'trouble logging in?' help page
- [Cleanup] to provide clearer exceptions

## [8.2.112] - 2023-10-23

- [Fixed] Error after saving dynamic model definition changes - fixes #193
- [Added] configuration notices to a more easily access app type components page - fixes #195
- [Cleanup] unnecessary reliance on rescue
- [Changed] link with #click-target-tab-activity-log-data-request to limit its possible container to the master panel, so tabs in the current master can be targeted - fixes #185
- [Added] dynamic definition config error feedback during editing - fixes #186 and #192
- [Changed] exception reporting often during startup for bad activity log configurations being loaded
- [Fixed] message formatting for invalid_error_message - fixes #191
- [Added] exception extensions to help with reporting error messages and backtraces
- [Fixed] expander carets are wrong direction - regression - fixes #190
- [Added] embedding of page layouts within standalone (Study Info) pages, allowing a full set of forms to be presented in order using an activity log
- [Changed] form fields changed but not saved warning to make it clearer
- [Added] CSS for inline buttons
- [Fixed] user access controls for *limited_if_none* to work correctly in all combinations, especially with assign_access_to_user_id - fixes #184
- [Added] headless browser testing option without relying on Xvfb - fixes #182
- [Fixed] calculate "all" conditions fails with condition: '<>' when the value is NULL - fixes #180
- [Fixed] error when a field has a validate: key and the validation fails - fixes #179
- [Fixed] Import CSV in admin panel fails to import UTF-8 data - fixes #178
- [Fixed] _fpa_substitution.js get_data() merges master data over the original instance data, breaking id, created_at, etc - fixes #175
- [Fixed] scrolling after saving a new model reference embedded in am activity log jumps to top of list - fixes #176
- [Added] documentation to clarify reference sorting in extra options view_options.sort_references
- [Fixed] scroll-to-target jumping back up to a link outside the current block - fixes #173
- [Changed] handling of panel tab caption to ignore blank entries that include carriage returns - fixes #172
- [Fixed] view_options.sort_references failing with an exception if a value being sorted is null - fixes #164
- [Refactored] to remove duplicated model reference related methods
- [Fixed] tag substitutions create [[functional directive]] output, to prevent raising an exception, or being manipulated by user data

## [8.2.104] - 2023-10-23

- [Fixed] release builds to include linked source directories correctly

## [8.2.103] - 2023-10-23

- [Bumped] version
- [Fixed] CHANGELOG

## [8.2.102] - 2023-10-23

- [Bumped] version

## [8.2.100] - 2023-10-19

- [Added] :current_user_roles SQL substitution to provide an array[] of current user active role names
- [Added] documentation for report SQL substitutions
- [Fixed] filtering of config libraries to include name, so we can directly link to them from dynamic def admin pages

## [8.2.99] - 2023-10-18

- [Added] the ability for reference action captions to incorporate more extensive substitutions
- [Added] preprocessing of templates to convert ReStructure specific tag formatters {{embedded_report_...}} {{glyphicon_...}} and {{tag::formatter...}} to new handlebars helpers

## [8.2.98] - 2023-10-17

- [App-Specific] [Added] study info app specific functionality

## [8.2.97] - 2023-10-17

- [Fixed] incorrect save making a syntax error when editing a config library attached to an activity log breaks the app
- [Changed] ui page ... templates to prevent them from making curly substitutions
- [Fixed] presentation issues with forms embedded in study info pages
- [Fixed] admin capability to allow user access control administration
- [Added] better admin index UI if no capabilities for a section
- [Fixed] error in admin panels that have user access control tabs when an admin does not have that capability

## [8.2.96] - 2023-10-16

- [Fixed] missing tag in UI templates breaks UI

## [8.2.95] - 2023-10-12

- [Added] ::general_selection_label formatter
- [Added] limited UI tag substitution lookup of associations, based on model_references in data
- [Fixed] front end formatter for YAML
- [Fixed] failed hash jumps and avoid JS errors

## [8.2.94] - 2023-10-11

- [Added] migration rule so field names ending with _json are automatically typed as jsonb in database
- [Added] triple curly substitution notation to return a data object for storing into a JSON DB field
- [Added] ::json and ::yaml formatters for substitutions
- [Fixed] URL hash opening a tab, but not closing automatically opened tabs
- [Fixed] issue trying to cast a True value with true_if_1 - check if the cast function exists and if not just return the original
- [Added] admin panel filtering of client requests

## [8.2.93] - 2023-09-27

- [Fixed] filter_params when there is no disabled field
- [Added] the ability to hide "disabled" filter in admin pages if it is not needed
- [Added] ability to filter client requests, and linked this from the redcap project requests summary panel
- [Added] redcap project admin option to prefix a config library to the dynamic model, so it always appears after an update
- [Fixed] Redcap extra fields (chosen array fields) so correct calculation of missing fields in dynamic model can be made

## [8.2.92] - 2023-09-26

- [Added] the ability to ignore or disable deleted Redcap records
- [Added] documentation for Redcap project admin
- [Changed] handling of data_options.add_multi_choice_summary_fields
- [Changed] presentation of Redcap project admin details block
- [Changed] "force reconfiguration" action to warn users that it is destructive and provide a confirmation to continue
- [Fixed] handling of Redcap record identification for repeating instruments

## [8.2.91] - 2023-09-25

- [Fixed] build script
- [Fixed] devise error message interpolations

## [8.2.90] - 2023-09-25

- [Changed] release script to attempt to avoid dependence on "git flow"
- [Changed] Changed login messages to confirm if an issue is with admin or user account

## [8.2.89] - 2023-09-25

- [Bumped] version

## [BAD VERSION] - 2023-09-25

- [Changed] multiple items for org specific assets and defaults
- [Moved] app/assets/images directory to restructure-app repo for org specific assets
- [Remove] outdated favicon
- [Changed] short links defaults
- [Added] default_logo substitution for message templates
- [Fixed] out of date flash when the next page is opened
- [Fixed] re-enabling of views

## [8.2.82] - 2023-09-20

- Rebuild

## [8.2.81] - 2023-09-20

- [Changed] handling of versions in build

## [8.2.80] - 2023-09-20

First attempt at building with app and organization specific files in restructure-apps repo

## [8.2.77] - 2023-09-19

- [Changed] location of app and organization specific directories and files to move them to restructure-apps repo, so we can move to real forking model for repositories

### Transferred from Harvard @8.2.76 - 2023-09-19

#### [8.2.76] - 2023-09-19

- [Fixed] version ordering to ensure that versions with very close timestamps are ordered correctly
- [Changed] handling of dialog substitutions where the tag is missing, to prevent exceptions that are hard to diagnose
- [Changed] loading of dynamic definitions to avoid loading items where the available schemas prevent access to the underlying table
- [Added] singular association for dynamic defs with a subject view handler
- [Fixed] valid record type options to allow selection of any valid key name

#### [8.2.75] - 2023-09-18

- [Fixed] issue adding new views

#### [8.2.74] - 2023-09-18

- [Changed] handling of dynamic model view updates to only update SQL if definition changed. Comment changes now don't trigger the update. And dependent objects are listed if the view can't update because of them
- [Fixed] error reporting and startup failures on import and when config libraries don't contain YAML references
- [Fixed] error page css path

#### [8.2.73] - 2023-09-14

- [Added] app type import "skip fail" option and provide partial success and improved failure messages
- [Fixed] admin panel raising exception if a model loaded but there was no underlying table/view
- [Fixed] incorrect migration being generated if the model exists but underlying table/view doesn't

#### [8.2.72] - 2023-09-12

- [Fixed] issue generating unnecessary migrations during app import
- [Changed] presentation of app type import
- [Fixed] registration of user from template having role not assigned to an app type
- [Added] dry-run and update with changes (regardless of updated_at timestamp) options to app type import
- [Changed] implementation of app type importing for simplicity and to avoid errors
- [Fixed] issue disabling dynamic definitions in admin panel

#### [8.2.71] - 2023-09-11

- [Fixed] tracker_history_id as an override in subject view handler for edge cases

#### [8.2.70] - 2023-09-07

- [Added] tracker_history_id as an override in subject view handler
- [Added] override ability for data attribute in external ids
- [Added] positioning of details panel components, by making dynamic models with negative position values appear before standard subject, contact and info blocks
- [Added] auto refresh after restarting server through server info
- [Added] instructions for adding dialog template when none are in the current dynamic def

#### [8.2.69] - 2023-09-07

- [Added] dialog_before list in dynamic def admin panel (and cleaned up styling)
- [Added] info to help with adding config libraries to dynamic definitions in the admin panel
- [Added] message template export for "ui page css/js" templates
- [Changed] template retrieval through Ajax to cache
- [Changed] "show caption before" to ignore missing tag by default
- [Changed] app type import to apply models in order of update and only update new items (unless force is set)
- [Changed] listing of libraries included in dynamic definitions admin
- [Changed] export of app type configurations to avoid generating migrations every time
- [Fixed] flash issues when session ended or for AJAX requests
- [Fixed] regression of export of dialogs related to dynamic models

#### [8.2.68] - 2023-09-05

- [Bumped] version

#### [8.2.67] - 2023-09-05

- [Added] improved UI for app types and upload
- [Added] server configuration checks with quick indicator on admin and server info pages
- [Added] admin app type documentation
- [Added] the option to import an app type forcing update of all components, rather than relying on the updated_at timestamp
- [Added] status information and additional setup details to admin app type list
- [Added] status information about the app and its configuration to app type import results
- [Changed] viewing of components related to the current app type, by adding a category if one is available
- [Changed] the error telling a user they don't have access to an app to make it clearer what the possible issue is
- [Changed] handling of UI template load failure to improve information to end user
- [Fixed] highlight resetting of hash linked items
- [Fixed] disabling of app types incorrectly on import
- [Fixed] generation of migrations that have index names that are too long for Postgres
- [Fixed] script error reading options from command line for filestore setups

## [8.2.66] - 2023-09-05

### Transferred from Viva @8.2.65 - 2023-09-05

#### [8.2.65] - 2023-08-24

- [Fixed] uncollapse-target-parents UI option

#### [8.2.64] - 2023-08-24

- [Added] ability to address !last element when using hash toggles
- [Fixed] UI error when reloading a page

#### [8.2.63] - 2023-08-24

- [Updated] gems to address CVEs: Puma - CVE-2023-40175; Rails - CVE-2023-38037
- [Fixed] css double border on certain blocks in activity logs
- [Added] tab caption to activity log definitions
- [Fixed] issue with data-open-tab-before-request if the panel had already opened
- [Changed] mr-expander link hashes to use the context of the current activity log outer block, and to only expand if not already expanded

## [8.2.62] - 2023-08-21

### Transferred from Harvard @8.2.60 - 2023-08-21

#### [8.2.59] - 2023-06-12

- [Added] templates for US terms of use to seeds
- [Changed] Refactored constants for registrations

### Transferred from Project Viva @8.2.61 - 2023-08-21

### [8.2.61] - 2023-08-17

- [Fixed] "if" substitution conditions not recognizing integers as existing
- [Added] javascript spec tests for conditional substitutions and current_user_roles

### Transferred from Project Viva @8.2.58 - 2023-08-16

#### [8.2.58] - 2023-08-14

- [Fixed] create_reference trigger to write user_id correctly if force_create is set
- [Fixed] user profile to check against created_by_user_id if it exists in a resource
- [Added] more information to debug user not able to access a container
- [Added] information to manage users page with links to user self-registration and invite code
- [Fixed] jump to bad CSS link

#### [8.2.57] - 2023-07-25

- [Fixed] UI current_user_roles
- [Fixed] id_hyphenate in UI

#### [8.2.55] - 2023-07-25

- [Fixed] scrolling issue
- [Added] simple mr-expander link hash toggle
- [Added] styling for static model reference captions and new form blocks

#### [8.2.54] - 2023-07-25

- [Added] substitution for user roles to allow #if evaluations
- [Added] invitation code to substitutions
- [Fixed] specs for xhr 404 results
- [Fixed] user login instructions for no MFA

#### [8.2.53] - 2023-07-24

- [Updated] gems and javascript modules
- [Fixed] loading of sample form in activity log admin when using a temporary master id
- [Fixed] issue with record labels if no config available

#### [8.2.52] - 2023-07-12

- [Added] result_label option to references config, documented also_disable_record, and added id to markup for reference result caret
- [Changed] handling of errors in notifications during sign-up
- [Added] master_id handling to embedded_report_ substitution
- [Added] link hash handling of toggle-target- and click-target- for smart links
- [Changed] default handling of BASE_URL

#### [8.2.51] - 2023-07-11

- [Added] field_options blank_value dynamic definition option to allow persisted blank field values to be set
- [Fixed] report admin not allowing configurations to be submitted
- [Fixed] padding in help sidebar using study info content

### Transferred from Project Viva @8.2.50 - 2023-07-06

#### [8.2.50] - 2023-07-05

- [Fixed] cleanup issues converting html to markdown
- [Fixed] issue preventing navigate away from page if files were uploaded to a container
- [Changed] handling of 404 errors to show nice custom page

#### [8.2.49] - 2023-07-04

- [Added] contact information to static error pages
- [Added] 502 specific error page

#### [8.2.48] - 2023-07-04

- [Changed] email address used to notify of user registration events

#### [8.2.47] - 2023-07-04

- [Fixed] notify_failure bug in ApplicationJob
- [Changed] handling of missing batch user in message notifications

## [8.2.44] - 2023-06-26

- [Added] user self-registration checkbox to agree to GDPR and non-GDPR terms of use

### Transferred from Harvard @8.2.43 - 2023-06-15

#### [8.2.43] - 2023-06-15

- [Added] tracker notes display line breaks
- [Added] batch_trigger run_at and run once
- [Added] bad configuration protection for calc_action condition
- [Changed] rspec tests for reliability
- [Changed] creation of external id search reports to provide a better UI and correct category
- [Fixed] notification of password expiration to include the correct time in the email
- [Fixed] and documented password expiration notifications tests
- [Fixed] bugs in app import and model generation
- [Fixed] handling of failures in background and batch jobs
- [Fixed] bugs in report admin criteria definer UI
- [Fixed] issue showing generated reports (null description was not handled)
- [Fixed] report criteria labels to avoid incorrect capitalization and HTML markup

#### [8.2.42] - 2023-06-12

- [Fixed] file report failing to download multiple files
- [Fixed] label markup issues
- [Fixed] incorrect message telling user they are not authorized to download files

#### [8.2.41] - 2023-06-01

- [Added] ability to traverse element through arrays in calc actions

#### [8.2.40] - 2023-04-24

- [Fixed] issue attempting to save results of pull_external_data if there is nothing to save
- [Added] set of conditions for this and element comparison
- [Added] success_if option to pull_external_data trigger

## [8.2.38] - 2023-05-23

### [8.2.37] - 2023-05-23

### Transferred from Project Viva @8.2.37 - 2023-05-23

- [Fixed] date and time formatters and provided consistent spec tests
- [Fixed] issues showing and editing tag select fields
- [Fixed] calculation that incorrectly showed an edit button even if the dynamic model user access controls did not allow editing

## [8.2.35] - 2023-05-17

### Transferred from Harvard @8.2.34 - 2023-05-17

#### [8.2.34] - 2023-05-16

- [Added] json_parse and numeric index selection to substitutions
- [Added] logging to pull
- [Added] documentation of substitutions
- [Added] full set of options to tag substitution and formatting on front end. Refactored to new class files.
- [Added] API sample for Marketo webhook
- [Changed] documentation for administration of admins
- [Fixed] migration of view SQL when using @library definitions in the dynamic model

#### [8.2.33] - 2023-05-08

- [Fixed] pull_external_data with save_trigger_results

#### [8.2.32] - 2023-05-08

- [Added] pull_external_data to post data with substitutions

## [8.2.28] - 2023-05-04

### Transferred from Viva @8.2.27 - 2023-05-04

#### [8.2.27] - 2023-05-03

- [Fixed] correct display of redcap radio, select and tag select fields

#### [8.2.26] - 2023-05-03

- [Added] Firefox / geckodriver installation details to README
- [Fixed] passing of _general_selections data back to form display
- [Fixed] capitalization of certain fields

#### [8.2.24] - 2023-04-27

- [Fixed] regressions in UI

## [8.2.20] - 2023-04-25

### Transferred from Harvard @8.2.19 - 2023-04-25

#### [8.2.19]

- [Added] post requests to pull_external_data save trigger
- [Added] temporary results storage in save_trigger_results, available to if conditions and other pull_external_data url substitutions
- [Added] calc actions for ILIKE and ~*
- [Added] this: field: element: comparisons in if
- [Fixed] display of ui template blocks with substitutions showing with HTML tags
- [Fixed] display of null in tracker notes field

#### [8.2.17]

- [Fixed] migration generator bugs based on options hash / attributes

#### [8.2.15]

- [Fixed] encryption of api keys for Redcap
- [Removed] gem debase and ruby-debug-ide
- [Fixed] exception handling on bad API key, allowing Redcap project form to be edited

#### [8.2.14]

- [Added] configuration to specify a user or app_type for notification configurations to ensure that background jobs run with a consistent user
- [Changed] tracker record updates to ignore a missing item record being specified, since in certain dynamic model views the update triggering the tracker update may have hidden the actual record
- [Added] no_masters option to calculation of conditions, to allow a specific table to be queried directly
- [Added] configurable text for credential change text
- [Fixed] handling of code blocks in markdown
- [Fixed] unnecessary capitalization of tracker notes

## [8.2.12] - 2023-04-13

- [Fixed] public_pages by moving to info_pages to work around deployment issue on Elastic Beanstalk

## [8.2.10] - 2023-04-13

- [Fixed] bug in Zeitwork class loading
- [Fixed] admin app type components panel and standalone page not loading

## [8.2.1] - 2023-04-11

- [Changed] to Rails 6 and Ruby 3

## [8.1.14] - 2023-04-06

### Transferred from Harvard @7.4.169 - 2023-04-06

- [Added] {{#if}} conditional display in caption_before show mode
- [Added] UI caption formatters for ::date ::time etc
- [Added] condition evaluation outside of the current master record by specifying 'masters' as the first table.
- [Fixed] default conversion of markdown to html for email and dialog templates
- [Fixed] handling of current_user in add_tracker and improved conditional testing
- [Fixed] failing save triggers on Redcap record storage by setting the current_user
- [Fixed] user_preference can be missing

## [8.1.13] - 2023-03-08

### Transferred from Harvard @7.4.165 - 2023-03-08

- [Changed] admin panels for better presentation and improved navigation between related items
- [Fixed] batch_trigger not being removed when dynamic def is disabled

### Transferred from Harvard @7.4.160 - 2023-02-22

- [Added] batch_trigger handling for dynamic definitions
- [Added] initialization of configurations current_version option for dynamic defs
- [Added] improved logging in failed access to alternative id field
- [Added] script to setup new NFS groups for filestore
- [Added] env var configuration for filestore max group id (FILESTORE_MAX_GRP_ID)
- [Changed] handling of dynamic definitions to handle changes better
- [Changed] dynamic def handling of associations in readiness for Rails 6
- [Changed] rails log search string default
- [Changed] the admin panel to present the app components, consistent styling and better admin buttons flash
- [Changed] admin bar to move admin panel and logout buttons to top nav bar
- [Changed] naming to attempt to resolve delayed_job issues with recurring batch jobs
- [Fixed] duplicate class attribute
- [Fixed] anonymization issue breaking DICOM image viewing
- [Fixed] reloading of dynamic definition in batch template processing
- [Fixed] issues with batch_trigger scheduling and limits

## [8.1.11] - 2023-01-19

### Transferred from Harvard @7.4.152 - 2023-01-17

- [Changed] the admin panel to present the app components, consistent styling and better admin buttons flash
- [Fixed] duplicate class attribute
- [Added] form change checking and warning if navigating or performing activity log action that would lose changes
- [Added] useful error message for update_reference when no reference found
- [Changed] session timeout counter to clear the flash if another tab has refreshed the session
- [Fixed] constant autoloading error
- [Fixed] error where id not available in editable report row
- [Added] configuration of logging levels
- [Fixed] Markdown editor add image, which only showed selectable images from first container in app
- [Change] to ensure a portal page shows a Not Found error if a page with the matching slug is not found
- [Changed] handling of requests that don't have a matching route, to avoid spamming of the logs
- [Added] warning to user if there is an error that breaks the markdown editor saving changes
- [Fixed] page layouts to ensure dashboards can show activity logs in a traditional view (rather than as a info page layout)
- [Fixed] dashboard charts when view_options not set
- [Added] the merging of editable table rows with static cells
- [Fixed] report result viewing to show based on configurations
- [Added] report view_options.prevent_adding_items to prevent create in editable reports even if user has access to create report entries
- [Fixed] report edit breaks resizable textarea
- [Added] activity log admin clickable activities
- [Added] more information to activity log details panel
- [Added] report results handler to add blocks based on specific array fields
- [Added] report results_handler view option to add custom handlers
- [Added] ability to add chosen.js to more fields and fixed filtering
- [Added] rspec method to change app settings without spamming results
- [Changed] general selections so that they are not cached on the front end, since this is incorrect, and may also expose data to users in the Javascript console
- [Changed] login to force username to be lowercase
- [Changed] print css to resize report results block to be full set of data
- [Changed] styles to allow better handling of hidden file attachment blocks
- [Fixed] handling of calc_if against uncommon cases, especially current user evaluations
- [Fixed] issue returning incorrect values in selections for template configs
- [Fixed] capitalization in multi\_ fields
- [Fixed] admin report controller item type filter name display
- [Added] information to the update_reference documentation
- [Changed] handling of dynamic options parsing to provide more information, especially in app type imports
- [Changed] grep of Rails log to include additional context after match
- [Fixed] regression of use_current_version
- [Fixed] sidebar not showing when link clicked in certain pages or blocks
- [Fixed] infinite recursion on a tag*select*... field definition
- [Changed] build script to handle removed gems
- [Changed] grouping of production gems that really only should be used for asset build
- [Changed] viewing of the the admin password change document intended for end users

## [8.0.49] - 2022-11-10

- [Changed] feature rspecs to use latest Capybara and Selenium, and support a new Docker test container

### Transferred from Viva @8.0.119 - 2022-11-22

- [Fixed] created_by_user_id for items that do not have a master association (transferred directly from Harvard)
- [Added] simple mechanism for substituting list_id into report criteria text
- [Changed] report criteria select fields to setup with "chosen" even if not multiple

### Transferred from Viva @8.0.118 - 2022-11-15

- [Added] correct lookup of choice_label and tags in reports, with formatting of tags on submitting edit report changes
- [Changed] import error message
- [Added] handling of help sidebar navigation and editor tag cleanup
- [Added] glyphicon substitutions in study info pages
- [Added] app configuration option for "help index path" - allows help icon to link to a portal page for example
- [Changed] styling of editor dialogs
- [Changed] running of tests to mock AWS APIs by default
- [Fixed] glyphicon substitution in show mode

## [8.0.48] - 2022-10-27

- [Changed] version of Puma to the new 6.0 - to test breaking changes in staging environment

## [8.0.47] - 2022-10-26

### Transferred from Harvard @7.4.134 - 2022-10-26

- [Added] configuration for country select dropdown - priority items are configurable
- [Added] cache handling to avoid multiple requests for definitions being made and refactored Javascript \_fpa.cache
- [Changed] README for bindfs
- [Changed] caching of master search results template
- [Changed] handling of select_record_from... to handle no associations cleanly when the target has no master association
- [Changed] first time help page to not load during 2FA setup
- [Changed] 2FA so setup can't be skipped
- [Fixed] bugs, comments

## [8.0.46] - 2022-10-25

- [Added] default settings for organization specific settings not to be transferred up/downstream

### Transferred from Viva @8.0.112 - 2022-10-25

- [Added] configuration for country select dropdown - priority items are configurable
- [Changed] README for bindfs
- [Fixed] bugs, comments

## [8.0.45] - 2022-10-11

### Transferred from Harvard @7.4.127 - 2022-10-11

- [Added] two step MFA at login
- [Changed] help information for 2FA setup and login
- [Added] seeds for user notifications report and supporting admin items
- [Added] configuration specific documentation for "manage users" and improved template documentation
- [Added] admin functions to unlock user accounts
- [Added] e_signature script class to refactor and avoid client side errors
- [Fixed] issue viewing dynamic model definition when the db table is missing
- [Fixed] CSV generation and import of files with master_id field
- [Fixed] alert showing if any master record is open in list, even if it is not the master record with the alert
- [Fixed] blocking on piped processes
- [Fixed] general selection preparation for dynamic definitions with no master association
- [Fixed] initialization loading of full database of edit field selections
- [Fixed] handling of filestore exceptions in regular controllers

## [8.0.44] - 2022-09-16

### Transferred from Viva @8.0.109 - 2022-09-16

- [Added] real handling of UI timezones and formats, using Luxon library
- [Added] option when clicked to expand a master tab, others will be closed
- [Added] image list to custom editor
- [Added] server info Rails log search
- [Changed] handling of report criteria forms, refactoring to allow fix to support embedded reports linked from embedded reports to work
- [Changed] modal scrolling control and secure view over modals
- [Fixed] "close other tabs" for single master view
- [Fixed] scroll to on embedded forms and option to prevent reload of parent on save of reference to fix save_action scrolling
- [Fixed] iframe sandboxing
- [Fixed] refresh outdated dynamic definitions
- [Fixed] embedded report links and tree table table
- [Fixed] incorrect handling of result data lookup for select fields when empty dataset
- [Fixed] big select with absolutely unique field id
- [Fixed] usability and editing issues in custom editor
- [Fixed] inability to edit report with bad options
- [Fixed] table tree to only set up its own block
- [Fixed] report_options causing errors in lists
- [Fixed] tree view opacity during load
- [Fixed] small issue with admin reports criteria
- [Fixed] issues with show_modal
- [Fixed] open-in-sidebar for study info pages
- [Fixed] small issue with tree table attempting to setup regular table reports

## [8.0.43] - 2022-09-06

### Transferred from Harvard @7.4.122 - 2022-09-06

- [Added] view of report criteria in admin
- [Fixed] failure trying to add a new redcap project

## [8.0.42] - 2022-09-01

- Bumped version

## [8.0.39] - 2022-09-01

### Transferred from Viva @8.0.97 - 2022-09-01

- [Added] show_if generation from Redcap branching logic
- [Added] jasmine-browser-runner to replace old gem and support script app-scripts/jasmine-serve.sh
- [Added] ability to force update of a redcap dynamic model
- [Added] Redcap pull generation of array summary fields for multiple choice checkboxes
- [Added] multilevel functionality to report trees
- [Added] bootsnap
- [Added] password regex option and refactored entropy results
- [Added] disabling of 2FA for user and admin independently
- [Added] tree view option for reports
- [Added] ui templates for messages in change and forgot password form
- [Changed] new and edit password forms for usability
- [Fixed] sandbox of iframes (reports and message notifications) to allow popups from links
- [Fixed] field types not being passed to UI templates for standard subject types

## [8.0.37] - 2022-08-15

### Transferred from Harvard @7.4.120a - 2022-08-15

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

## [8.0.36] - 2022-08-05

- [Added] ui templates for messages in change and forgot password form
- [Fixed] field types not being passed to UI templates for standard subject types

## [8.0.35] - 2022-07-18

### Transferred from Viva @8.0.88 - 2022-07-18

- [Added] other_user_is_creator from reference option
- [Fixed] context issue with edit form captions
- [Added] reference definition without_reference: outside_master
- [Fixed] passing user_preference to front end
- [Added] ability for standalone pages to be loaded in the help sidebar
- [Added] escaping for curly brackets in substitutions
- [Changed] documentation for optional MFA and added substitution info
- [Added] invitation code to registration
- [Added] view_original_case field option to prevent the UI capitalizing downcased fields
- [Fixed] help sidebar in standalone help pages
- [Added] first login sidebar popup
- [Added] notifications option to user menu and updated help with notifications page
- [Added] help link handling in study info pages
- [Changed] substitutions to allow glyphicons and notifications_from_email address
- [Fixed] issue with nested ordered lists in markdown editor
- [Fixed] hiding modal on submitting embedded form & no_report_scroll not enabling full page scroll
- [Fixed] search doc with download/in route form - plus refactored to DRY code
- [Added] message template UI blocks for registration forms and user preferences
- [Added] admin documentation for message templates
- [Added] caption before references with extra log types
- [Added] on_master_id as embedded_report extension
- [Changed] expand_reference action to scroll to result
- [Fixed] issue where activity log panels don't get fully scrolled to
- [Fixed] issue where report list updates fail if user only has view_report_not_list access
- [Updated] expand_reference documentation
- [Added] preprocessing to CSV imports for array fields
- [Added] sample use of API in Ruby scripts
- [Added] study info content migrator using api
- [Changed] to handle select_record fields not associated with master and better documentation
- [Changed] allowable fields in import CSV to allow "disabled"
- [Fixed] issue where incorrect page layout nav configuration breaks UI completely

## [8.0.34] - 2022-06-13

### Transfer from Harvard 7.4.111 - 2022-06-13

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

### Transfer from Harvard 7.4.106 - 2022-06-01

- [Fixed] issue related to definition loading and select from record configs

## [8.0.31] - 2022-06-01

### Transferred from Viva @8.0.74 - 2022-06-01

- [Added] admin capabilities to allow admins to be restricted in what they can administer
- [Added] responsive styling to secure viewer
- [Added] infinite scrolling to secure viewer
- [Added] option for nfs_store: view_options: show_file_links_as: path to enable path URI in filestore browser
- [Added] path based access to container files, and a link provided in stored file and archived file forms
- [Added] consistent secondary key handling for activity logs
- [Added] download of files using a download_path param
- [Added] showing select*from*... values based on live data and master associations, not just dynamic definitions
- [Added] global app definition of nav links, and ability for icon to be used without a label
- [Added] show_as iframe for report cell and fixed tags handling
- [Added] filestore browser to appear in edit forms, if view_as: edit: filestore is set
- [Added] if block substitions
- [Changed] if block substitutions to allow for multiline text

- [Fixed] failure attempting to edit external id
- [Fixed] date and time formatting in reports presented as lists
- [Fixed] handling of always_use_this_for_access_control, save trigger success and skip_if_exists
- [Fixed] calc action to use conditions consistently
- [Fixed] issue with if block substitutions
- [Fixed] bug with using document secure viewer on second load of report results
- [Fixed] migrations related to reference views
- [Fixed] css for hiding empty captions
- [Fixed] issue adding new dynamic models
- [Fixed] recursive calling of save trigger within update_this and pull_external_data
- [Fixed] references: showable_if: calculation causing infinite recursion

## [8.0.30] - 2022-05-13

### Transferred from Viva @8.0.63 - 2022-05-13

- [Added] field_options: field_name: preset_value: option
- [Added] direct embed ability through options or field definitions
- [Added] viewing / editing of direct embedded item within a stored file
- [Added] pull_external_data save trigger
- [Added] full markdown support for master list header title
- [Added] change_user_roles option for_user to specify non-current user, and allow lookup of role names with calc reference
- [Added] tag select for records from tables / dynamic models
- [Changed] parallel tests script and specs for reliability
- [Changed] rules so master_id can be provided as a regular field, not a foreign key (for Redcap data for example)
- [Changed] handling of redcap pull to ignore excess fields in dynamic model
- [Changed] embedded_block to allow formatting of link and allow models related to a master to edit
- [Changed] gemfile to include puma in all environments, to allow latest version to be installed on beanstalk
- [Changed] styling of user profile panel
- [Fixed] dynamic migrations adding master_id foreign key field after creation
- [Fixed] show_if issues with object fields and referenced dynamic_models
- [Fixed] curly substitutions in javascript to traverse full dotted path
- [Fixed] substitutions for markdown to HTML incorrectly identifying HTML documents
- [Fixed] datepicker being hidden by modal view
- [Fixed] issue with caching of user roles and access controls not clearing when new role added
- [Fixed] issue with created_by_user_id
- [Fixed] issue with view_options in model references

## [8.0.29] - 2022-04-12

### Transferred from Viva @8.0.58 - 2022-04-12

- [Added] view_css support to regular panels
- [Added] force_not_valid option in create/update_reference and update_this
- [Added] ability for save_action to return the first result that matches an if condition
- [Added] users as a table to calculate against in \*\_if evaluations
- [Added] save_action expand_reference
- [Added] media queries to view css options
- [Added] activity log master and item associations for extra log types, allowing for substitutions against a specific activity
- [Added] defined_selector options to reports criteria to allow easy selector configuration based on central and model configurations
- [Added] 'never' option to always*embed*\*reference
- [Added] ability for an existing admin to add a new admin account if appropriate server setting allows
- [Fixed] limited_access_control using association master_created_by_user
- [Fixed] issue loading images when window not focused
- [Fixed] Fixed issue with simple true in show_if and save_action
- [Fixed] specs for stubbing and activity log definitions
- [Fixed] issues with dynamic reloading
- [Updated] puma to 5.6.4 - Procfile for AWS Beanstalk created during deployment must start the web: entry with bundle exec to use the bundled version

## [8.0.28] - 2022-03-08

### Transferred from Viva @8.0.52 - 2022-03-08

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

## [8.0.27] - 2022-02-09

### Transferred from Harvard @7.4.96 - 2022-02-09

- [Fixed] pregenerated and non-editable external identifier fields not to show
- [Changed] export of app-export migrations to go to a single app directory, not each schema directory
- [Added] app admin navigation for current app
- [Fixed] Beanstalk scripts
- [Updated] restart script to allow full EB restart of all app servers
- [Added] app type components page for easy viewing and navigation around an app
- [Added] ability to filter admin resources by id, ids or resource name

## [8.0.26] - 2022-01-12

### Transferred from Viva @8.0.39

- [Added] user self-registration, email confirmation and password reset
- [Changed] release script to allow clean container to be requested
- [Changed] change_user_roles trigger to allow app_type to be specified
- [Changed] ability to specify multiple checkboxes in report select items
- [Changed] css for mobile responsiveness, css vars and app styles
- [Changed] document library to correctly link to source repository
- [Changed] admin scripts to improve server configuration
- [Fixed] issue with active app types when specified with env var, since it returned an array not a scope

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
