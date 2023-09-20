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
