# Changelog for ReStructure

This file documents notable changes to the ReStructure project.

The format of this file is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

In short this means that version numbers, visible here and on the login page of the app match, and have a predictable format indicating how much change from the previous version has occurred.

The [Unreleased](#unreleased) section collects notes for unreleased changes and features, until they are absorbed into a formal release in a version number tagged section below.

Note that not every tagged version may be suitable for production use. A Github release will be created for any release tested in production, and may be marked below with the tag [Release].

Since [version 8.4.0](#840---2024-01-10) the convention is that releases made within forked repositories should be up-versioned with a patch release, *x.y.z+1*. When changes are incorporated back into the primary repo [consected/restructure](https://github.com/consected/restructure) a new minor release will be created, *x.y+1,0*.

## Unreleased

## [9.42.20] - 2026-04-14

- [Merged] release 9.42.19 back to develop
- [Fixed] parallel test failures in specs
- [Fixed] documentation link

## [9.42.19] - 2026-04-09

- [Merged] release 9.42.18 back to develop
- [Fixed] initial_show CSS class bug and added system specs - fixes #219
- [Fixed] select_user_with_role_ label resolution in reports and selections - fixes #333
- [Updated] parallel test scripts for better logging
- [Refactored] spec helper stability and layout cleanup - fixes #1020
- [Refactored] system spec navigation helpers - fixes #1020
- [Changed] parallel test script to accept command line args in place of environment variables
- [Fixed] bad exit message in parallel test retests
- [Added] api_access_only flag for API-only users to bypass 2FA setup - fixes #1025
- [Added] admin manage users system specs - resolves #1027
- [Refactored] admin manage users spec with helpers and context blocks - resolves #1027
- [Fixed] prepend_to_options gsub corrupting YAML with escaped quotes - fixes #1029
- [Fixed] config library _default: breaking configs when _definitions: appear below it - fixes #521
- [Added] versioned config library resolution for dynamic definitions - fixes #666
- [Added] config library timestamp check to dynamic definition cache invalidation - fixes #523
- [Fixed] duplicate admin panel server alerts - fixes #1035
- [Added] test for item flag name export filtering by app type - fixes #3
- [Fixed] tdd agent prompt
- [Added] item flag name import support and test - fixes #3
- [Added] secure viewer support for Redcap file links and filestore_view show_as option in reports - fixes #1040
- [Added] URL search formats to admin Master Records and External Identifiers panels - fixes #1041
- [Added] new agent prompts for feature branch management
- [Added] agent prompt to merge latest changes from up-develop branch to local develop
- [Fixed] admin Redcap project creation failing in non-ref-data app types - fixes #1043
- [Added] explicit serializer: Marshal to Dalli cache config to suppress security warning - fixes #1038
- [Added] 2FA upgrade spec, docs, OTP setup fix, and admin 2FA status column - fixes #1047
- [Fixed] message template form losing message_type and template_type on save - fixes #1049
- [Fixed] admin forms overriding saved select field values with filter params - fixes #1050
- [Added] URL fallback and XSS protection for report column show_as url - fixes #1053
- [Added] User Access Overview admin reports with 5 perspectives - fixes #706

## [9.42.18] - 2026-04-01

- [Merged] release 9.42.17 back to develop
- [Updated] structure.sql
- [Added] admin report preview action to fix auth issue - fixes #1000
- [Fixed] report table header cache key to include editable state - fixes #1000
- [Added] visual indicator on Edit table data button when fields are configured - fixes #1000
- [Changed] edit table data button to use ternary for btn class
- [Documented] create_reference specific_record option - resolves #221 (#1002)
- [Added] refactor prompt
- [Fixed] report tab to refresh instead of collapse when already expanded - fixes #87
- [Added] standalone dynamic model support to create_reference save trigger - fixes #1003
- [Fixed] user session timeout spec to finish in a reasonable time
- [Fixed] multi-file caching for Handlebars templates - fixes #1004
- [Fixed] redcap_email and redcap_phone fields showing blank in show mode - fixes #558
- [Added] full agent tool to tdd-implementation agent
- [Added] optional expire_datetime field to users and admins - fixes #330
- [Updated] DB structure to reflect recent migration

## [9.42.17] - 2026-03-24

- [Added] batch trigger API sync with association resolution and dynamic name substitution - fixes #996
- [Updated] copilot instructions to allow use of environment variables
- [Changed] Parsed Config panel to use CodeMirror YAML viewer - fixes #992
- [Fixed] _configurations key not being stripped in parsed_options_text - fixes #992
- [Added] parsed_options_text to resolve YAML anchors in Parsed Config tab - fixes #992
- [Added] admin panel styling fix
- [Fixed] stopPropagation called on jQuery element instead of event object - fixes #990
- [Fixed] Import CSV to auto-populate id, created_at and updated_at - fixes #991
- [Fixed] report criteria admin style issue

- [Security] updated gems to address Nokogiri security issue: <https://github.com/sparklemotion/nokogiri/security/advisories/GHSA-wx95-c6cv-8532>
- [Security] updated gems to address Devise security issue: <https://github.com/heartcombo/devise/security/advisories/GHSA-57hq-95w6-v4fc>

## [9.42.12] - 2026-03-05

## [9.42.11] - 2026-03-04

- [Merged] release 9.42.10 back to develop
- [Fixed] test database setup naming
- [Fixed] test setup
- [Added] object key passthrough in FieldDefaults.calculate_default for JSONB fields - fixes #943
- [Added] integration test for create_reference with JSONB object storage - fixes #943
- [Refactored] YARD docs and restored test cleanup guards for JSONB object passthrough - fixes #943
- [Added] shared defs for with: attribute values documenting object: wrapper for JSONB fields - fixes #943
- [Added] comprehensive specs for SaveTriggers::Case including integration tests - fixes #944
- [Refactored] save triggers to extract shared execute_trigger_list and store_trigger_results to base class - fixes #944
- [Refactored] case spec with helper methods to reduce config boilerplate - fixes #944

## [9.42.10] - 2026-02-27

- [Merged] release 9.42.9 back to develop
- [Fixed] session timeout not working due to CSP reports resetting session timer - fixes #925

## [9.42.9] - 2026-02-26

- [Added] a master records admin page - resolves #930
- [Added] user context to raise_flag_file_error in Mounter - resolves #649
- [Added] system spec for memcached connection panel with live memcached - fixes #886
- [Refactored] cache store spec and config per rubocop conventions
- [Changed] Dalli cache store to use meta protocol - fixes #886
- [Added] support for all HTTP verbs in pull_external_data trigger - fixes #928
- [Moved] copy-to-clipboard to fpa_form_utils, fixed {{master_id}} curl variable, generalised copy button CSS class
- [Added] "execute/awaitTerminal" to agent tools
- [Aligned] report save trigger key to get_report (was get_record)
- [Moved] report curl and save trigger generation into helper methods
- [Added] create master with associations API tests via pull_external_data - PR #929
- [Added] save trigger API endpoint specs for dynamic models and reports - resolves #652
- [Added] API definitions panel to admin dynamic definition and report views - resolves #652
- [Added] dynamic definition setup re: automatic migrations to agent instructions
- [Added] API create master with associations, transactional rollback, and API docs - fixes #924
- [Added] secure viewer enhancements: zoom display, custom zoom input, click-to-zoom, rotate CW/CCW, scroll position preservation, rotation clipping fixes - fixes #590
- [Added] documentation for APIs and facilitate clean return of API endpoint routes by ensuring STDERR is written to within the app for CLI messaging
- [Fixed] Rails log search page formatting
- [Added] clear all user roles action for admin User Roles page - fixes #671
- [Removed] dead _admin_redcap_status_indicators partial and brakeman entry, fixed trailing newline - fixes #905
- [Added] collapsible Missing Configurations panel to config status partial - fixes #905
- [Refactored] alerts panel: extracted helpers, removed duplication, simplified badge rendering - fixes #905
- [Changed] alerts panel header to show separate server and redcap badges with category colors - fixes #905
- [Added] collapsed alerts panel to admin index page, removed old popover alerts - fixes #905
- [Added] better test separation
- [Fixed] handlebars CLI call to avoid npx 128KB command line limit
- [Added] Handlebars CLI precompilation with batched template loading - fixes #873
- [Added] definition of new handlebars precompilation
- [Fixed] adding page layouts that have the same name as previously disabled page layouts
- [Fixed] failing admin message notifications and iframe report cells
- [Fixed] error handling for test DB setup

## [9.42.8] - 2026-02-20

- [Fixed] HTML entity encoding in javascript_tag heredoc blocks
- [Fixed] application layout
- [Fixed] CSP to be report only for a while
- [Fixed] CSP reports to avoid unauthenticated entries being accepted
- [Fixed] big-select JSON parsing and enabled CSP enforcement
- [Added] Content-Security-Policy with nonces for inline scripts and Handlebars templates - fixes #279
- [Fixed] test database setup scripts
- [Cleanup] small syntax items
- [Updated] app configs for specs
- [Fixed] template_option_mapping fields mutation and tag_formatter_spec general selection labels - fixes #901
- [Fixed] reload_this_spec and dynamic_model_spec test failures - fixes #901
- [Fixed] timing issues in player_data_entry_spec - fixes #901
- [Fixed] test isolation issues in tracker, save trigger, and NFS store specs - fixes #901
- [Fixed] activity log setup in background and transaction save trigger specs - fixes #901
- [Fixed] test isolation issue in upload_spec notification test - fixes #901
- [Fixed] test isolation issues in ExternalIdentifier specs - fixes #901
- [Fixed] parallel test FrozenError by skipping bootsnap for workers - fixes #901
- [Extracted] CodemirrorEditorSupport module to separate file
- [Refactored] CodeMirror editor helpers into FeatureSupport module for reusability
- [Fixed] admin_yaml_anchor_recovery_spec.rb - disable migrations to avoid thread/connection issues
- [Fixed] parallel test conflict in dynamic_model_options_spec - refs #901
- [Fixed] parallel test failures in DynamicModelSupport and reports specs
- [Fixed] issues writing to failing_specs.log file in parallel tests
- [Updated] copilot instructions to improve PR creation
- [Updated] gitignore of failed-archive testing flag
- [Added] descriptive error handling for flag file operations in Mounter - fixes #911
- [Fixed] MountArchiveJob failing when user app type changes - fixes #910
- [Updated] agent tool usage
- [Fixed] the setup of rspec browsers for system tests when checking if the port is in use already
- [Changed] agents to provide better tool use
- [Changed] rspec instructions for rails runner
- [Fixed] force-created parent records not creating embedded items when user lacks create access
- [Added] the ability to run multiple dev and test servers in multiple workspaces on the same machine, to support AI agents and human developers working simultaneously
- [Fixed] job reviews URL in job failure emails
- [Updated] documentation and specs - fixes #896
- [Added] comprehensive server info documentation for administrators - fixes #896
- [Converted] server info page to Bootstrap accordion for better usability - fixes #896
- [Refactored] NFS monitoring code - added constants, extracted helper, fixed Bootstrap grid - fixes #896
- [Adjusted] column widths for better label alignment in NFS source info - fixes #896
- [Removed] mount path display and fixed source filesystem extraction from gid mounts - fixes #896
- [Refactored] to show source filesystem separately with its own status - fixes #896
- [Fixed] test mocking issues - fixes #896
- [Enhanced] main admin page mountpoint status indicator tests - fixes #896
- [Implemented] NFS mountpoint monitoring functionality - fixes #896
- [Added] failing tests for NFS mountpoint monitoring - fixes #896
- [Fixed] Filestore actions like "send to trash", "move" and "rename" need to delay before submitting the "refresh" - fixes #899
- [Fixed] download button in the filestore secure viewer fails with an error when using a file field - fixes #897

## [9.42.7] - 2026-02-05

- [Rebuild]

## [9.42.6] - 2026-02-05

- [Added] Content-Security-Policy with nonces for inline scripts and Handlebars templates - fixes #279
- [Fixed] big-select JSON parsing and enabled CSP enforcement
- [Fixed] CSP reports to avoid unauthenticated entries being accepted
- [Fixed] CSP to be report only for a while
- [Fixed] missing session variable in app setup

## [9.42.5] - 2026-02-05

### From FPHS - PR #893 - 2026-02-04

- [Added] dynamic page title updates based on UI context - fixes #871

### From FPHS - PR #892 - 2026-02-04

- [Fixed] switchable ID to show first non-(none) ID on participant header - fixes #872

### From Consected - 2026-02-04

- [Fixed] asset cleaning to limit to test directories

### From Viva (with debugging contributions from FPHS) - PR #891 - 2026-02-04

- [Changed] edit form template to ensure filestore form is not inside the main form - fixes #884

### From Viva - 2026-02-04

- [Added] consistent app settings setup to system specs

### From Viva - PR #889 - 2026-01-04

- [Fixed] add_item_button hyphenated name for activity logs and external identifiers

### From Viva - PR #888 - 2026-02-03

- [Fixed] user NfsStore actions, to prevent them changing the user's app_type id for the UI - fixes 887

### From FPHS - PR #883 - 2026-02-03

- [Fixed] race condition in auto-run report tabs causing 0 results on tab rotation

### From FPHS - PR #882- 2026-02-02

- [Fixed] master tabs access control spec - related to #673

### From Viva - 2026-02-02

- [Added] option to release script to that must be set if we want to merge back from new-master branch after build

### From Viva - 2026-02-02

- [Updated] agent tool access

### From Viva - PR #879 - 2026-02-02

- [Fixed] undefined method 'definition' error when renaming or trashing filestore files - fixes #878

### From FPHS - PR #874 - 2026-01-27

- [Added] big-select field filtering implementation, documentation and full test suite

### From FPHS - PR #870 - 2026-01-23

- [Changed] embedded_block in report to allow URLs with /edit - fixes #325
- [Fixed] embedded_block in report to allow activity log URLs

### From FPHS - PR #868 - 2026-01-22

- [Added] activity log access summaries in admin panel - resolves #867

### From FPHS - PR #865 - 2026-01-22

- [Added] `active_sublist_values` option to page layouts `view_options` - fixes #584
- [Added] `sort_sublists` option to set default sort order (`'asc'` or `'desc'`) to page layouts `view_options`

### From FPHS - PR #864 - 2026-01-22

- [Added] a scope to exclude a role name from a user access controls query (required coalesce to work)
- [Added] the ability to show extra calculated columns in admin index lists
- [Added] UAC summary to Dynamic Model and External Identifier admin panels - fixes #859
- [Added] copilot agents and instructions to support AI agent workflows.
- [Split] out instructions into files scoped by applyTo metadata.
- [Added] agent personas based on <https://github.com/github/awesome-copilot>

### From FPHS - PR #860 - 2026-01-21

- [Added] access control filtering for master tabs nav dropdown - fixed #673

- [Fixed] External IDs panel blank when switching participants, resolves original issue #653 incorrectly addresed by PR #855  - fixes #857

### From FPHS - PR #856 - 2026-01-21

- [Fixed] view_options.alt_width_classes not working for external ID or dynamic models displayed in master panels - fixes #389

### From FPHS - PR #855 - 2026-01-20

- [Fixed] external IDs panel not showing content when switching participants  - fixed #653

### From FPHS - PR #854 - 2026-01-20

- [Fixed] error parsing JSON field when the content is an empty string - fixes #853

### From FPHS - PR #852 - 2026-01-20

- [Fixed] issue when users tried to reset their password with a previously used password, they saw confusing duplicate errors - fixes #340

### From FPHS - PR #851 - 2026-01-20

- [Fixed] switch_id_on_click for multiple external IDs - fixed #312

### From FPHS - PR #850 - 2026-01-20

- [Fixed] styling on admin log and long lines in YAML editors

### From FPHS - PR #849 - 2026-01-20

- [Fixed] spec test issues

## [9.42.1] - 2026-01-19

### From FPHS - PR #848 - 2026-01-19

- [Added] substitutions within save trigger pull_external_data headers, to support `Authorization: Bearer {{access_token}}` requirements - references #840

## [9.42.0] - 2026-01-19

### From FPHS - PR #39 - 2026-01-19

- [Fixed] batch_trigger not being removed when dynamic definition is disabled - resolves #39

### From FPHS - PR #845 - 2026-01-19

- [Fixed] #216 - Recreate triggers when field types change in dynamic models

### From FPHS - PR #844 - 2026-01-19

- [Added] detailed error logging to reload_this trigger - fixed #838

### From FPHS - PR #843 - 2026-01-19

- [Added] exclude regex field to Rails log admin viewer - fixed #751

### From FPHS - PR #842 - 2026-01-16

- [Added] extra debugging logging and exceptions

### From FPHS - PR #841 - 2026-01-14

- [Added] failed file field marker and retry logic for REDCap pulls - fixed #837

### From FPHS - PR #839 - 2026-01-15

- [Added] Redcap project buttons to retrieve "since" last retrieval or "all", and ensure the date to retrieve from represents the last successful retrieval - resolves #379
- [Added] Redcap project options for metadata_export_cache_time, record_export_cache_time, export_only_updated_records

### From FPHS - PR #836 - 2026-01-14

Fixed using field default 'current_user_email' fails in a report criteria default when viewed within the admin panel - fixes #620

### From FPHS - PR #835 - 2026-01-14

- [Fixed] master search results being requested from server twice in quick succession - fixes #834

### From FPHS - PR #832 - 2026-01-13

- [Fixed] tracker history ordering to use event_date::date DESC, id DESC so that events are ordered correctly based on event date "date without time" and latest insert - fixes #830

### From FPHS - PR #833 - 2026-01-13

- [Changed] the parsed config functionality for dynamic definitions to just show options text with merged libraries and defaults - resolves #831

## [9.41.6] - 2026-01-13

### From FPHS - PR #829 - 2026-01-13

- [Fixed] admin panel editing Activity Log locks up UI due to styling parsed config code - fixes #828

## [9.41.5] - 2026-01-12

### From FPHS - PR #827 - 2026-01-12

- [Fixed] incorrect listing of filesystem flag files
- [Fixed] specs for reliability
- [Fixed] cleanup of test database to also clean temp filestore test files
- [Added] save or batch trigger mechanism to reload "this" - resolves #824
- [Added] save trigger that acts as a transaction block around other save triggers
- [Added] save trigger that runs all the listed triggers in a single background job
- [Added] save trigger to add log entry - resolves #823
- [Added] save trigger to run a batch trigger in another dynamic model - resolves #822
- [Fixed] "Run Batch Now" button not working after saving a dynamic model definition
- [Fixed] broken YAML in dynamic model with view_sql prevents changes being saved
- [Added] developer documentation to show simple implementation of "AJAX Requests and Responses Using Regular Markup"
- [Added] ability for report row create and edit to operate for admins without explicit user access controls
- [Fixed] create_master to return a valid value
- [Added] more information to add_trackers failure if protocol name or id not found

### From Viva

- [Changed] custom editor tests to split out reusable helpers
- [Fixed] the markdown editor failing to paste multiple paragraphs of text successfully from Word docs - fixes #825

## [9.41.4] - 2026-01-08

### From FPHS - PR #819 - 2026-01-08

- [Fixed] create_reference force_valid: true option not working for standard "player" models - fixes #818

### From FPHS - PR #817 - 2026-01-08

- [Fixed] batch and save triggers not running the full set of triggers - fixes #816

### From FPHS - PR #815 - 2026-01-08

- [Added] feature to run dynamic model batch jobs immediately in the admin panel - resolves #814

### From FPHS - PR #813 - 2026-01-07

- [Added] tests and documentation for valid_if dynamic definition option - resolves #228

### From FPHS - PR #812 - 2026-01-07

- [Fixed] scenario where a user has been disabled but we still attempt to send a password notification, causing an exception - fixes #544

### From FPHS - PR #811 - 2026-01-07

- [Added] documentation for tag formatters Fixed implementation and test differences between Ruby and Javascript tag formatters - resolves #679
- [Fixed] failure to run DicomMetadataJob when the original user's app type id has changed - fixes #808

### From FPHS - PR #810 - 2026-01-06

- [Fixed] failure to run DicomMetadataJob when the original user's app type id has changed - fixes #808

### From FPHS - PR #809 - 2026-01-06

- [Fixed] user access control admin panel copy or editing item causes drop downs to lose values - fixes #395
- [Added] AI tools

## [9.41.3] - 2025-12-23

## [9.41.2] - 2025-12-23

Rebuild

## [9.41.2] - 2025-12-23

Rebuild

## [9.41.1] - 2025-12-23

### From FPHS - PR #806 - 2025-12-23

- [Added] memcached connection status, version and stats and DB server info in Server info - resolves #627

### From FPHS - PR #805 - 2025-12-23

- [Added] option to copy roles that also set the target user's disabled roles back to enabled - resolves #672

### From FPHS - PR #804 - 2025-12-23

- [Added] admin info panel to view a "parsed config" of dynamic definitions after the config libraries, cleaned configs and YAML anchors have been applied - resolves #795

### From FPHS - PR  #803 - 2025-12-23

- [Added] multiple repetitions to allow config libraries referenced within config libraries to be successfully imported within an app import - resolves #793

### From FPHS - PR #802 - 2025-12-23

- [Fixed] add_item_button incorrect markup for dynamic models - fixes #798

## [9.41.0] - 2025-12-22

- [Updated] gems and yarn

## [9.40.0] - 2025-12-22

### From Viva - 2025-12-22

- [Updates] to support improved testing and app import reliability

### From FPHS - PR #801- 2025-12-22

- [Fixed] NfsStore::Dicom::MetadataHandler bug when guarding against a missing file_path due to user not having appropriate user roles - fixes #796

## [9.39.0] - 2025-12-22

- [Updated] gems to address CVE:
  - CVE-2025-14762

### From Viva - PR #800 - 2025-12-22

- [Updated] gems to restrict connection_pool version

### From Viva and FPHS - PR #799 -2025-12-22

Combined effort related to both projects with similar issues.

- [Fixed] specs and test automation

Fixed-test-script

### From FPHS - PR #791 - 2025-12-07

- [Added] test scripts to aid automated testing
- [Changed] handling of test database cleaning using a Postgres user with appropriate privileges, rather than the superuser
- [Fixed] specs for reliability

Added brakeman ignore entry

### From FPHS - PR #789 - 2025-1205

- [Fixed] deprecation warnings for SCSS files - fixes #669

### From FPHS - PR #788 - 2025-12-05

Added more information when the save trigger add_tracker fails for some reason - fixes #280

### From FPHS - PR #648 - 2025-12-05

- [Added] Redcap transfer to include failed files count - resolves #648

### From FPHS - PR #617 - 2025-12-05

- [Added] notify save trigger to allow curly substitutions for emails, users and other configurations -  resolves #617

- [Fixed] documentation related to notify save trigger

- [Allow] use of `return_value_list` calculated value to return multiple results form the data for emails and phones in notify save trigger
Fixed documentation related to notify save trigger

Allow use of `return_value_list` calculated value to return multiple results form the data for emails and phones in notify save trigger

### From FPHS - PR #785 - 2025-12-05

- [Changed] handling of Redcap projects with transfer mode "none" to reinforce its meaning as "never transfer this project" - resolves #630

### From FPHS - PR 784 - 2025-12-05

- [Changed] database setup for better testing (avoid need for sudo and remove Filestore temp files)

### From FPHS - PR #783 - 2025-12-05

- [Added] a warning indicator on the Redcap Project admin panel link to show if any scheduled pulls are marked as "failed" - resolves #639

### From Consected - PR #782 - 2025-12-03

- [Added] dynamic model batch_trigger job details and link in dynamic model admin panel - resolves #691

### From Consected - PR #781 - 2025-12-03

- [Added] version diffs to config_libraries in a new admin panel tab - resolves #780

## [9.38.0] - 2025-12-03

- [Updated] CHANGELOG.md with git commits

## [9.37.0] - 2025-12-03

- [Updated] gems

### From Consected - PR #778 - 2023-12-03

- [Added] a link from dynamic model, activity log and external identifier admin panels to search the relevant history table - #647

## [9.36.0] - 2025-12-03

### From FPHS - PR #777 - 2025-12-03

- [Fixed] issue where tables appear in multiple schemas in the search path, a dynamic model may warn that that the table schema name is incorrectly defined - fixes #651
- [Added] small fixes for testing reliability

### From Consected - PR #776 - 2025-12-03

- [Added] diff of versions in dynamic definitions admin panels - resolves #744

### From Consected - PR #775 - 2025-12-03

- [Added] check of dynamic definition options for redefinition of standard anchors - resolves #678

### From Consected - PR #774 - 2025-12-03

- [Added] show_if referencing embedded_item data in its conditions - resolves #759

## [9.35.0] - 2025-12-02

### From FPHS - PR #773 - 2025-12-02

- [Changed] default test browser to Chrome - related to #753

### From FPHS - PR #772 - 2025-12-02

- [Added] view reference info to dynamic definiition admin details panels
- [Fixed] AppGenerator drops reference views if they have dynamic model definitions, but doesn't recreate them afterwards - fixes #771

## [9.34.0] - 2025-12-01

- [Updated] Ruby version to version 3.4.7
- [Updated] gems

## [9.33.0] - 2025-12-01

### From FPHS - PR #770 - 2025-12-01

- [Fixed] truncation of long radio button labels
- [Fixed] caption_before fields that are empty from being added incorrectly in the model generator
- [Fixed] small admin panel display bug
- [Fixed] setting option_type from active_value - fixes #769

### From FPHS - PR #768 - 2025-12-01

- [Fixed] generation of real show_if when choice values have underscores - fixes #650

### From FPHS - PR #767 - 2025-12-01

- [Added] option type handling to Redcap model generation - resolves #765
- [Fixed] issue with accidental merging option configs into _default options
- [Added] ability for Redcap  forms represented as option_type to acccess fields in other forms for branching logic show_if evaluation - resolves #764
- [Added] hidden field type to hide captions, labels and fields while keeping the value available for show_if evaluation

### From FPHS - PR #766 - 2025-11-30

- [Cleanup] configuration of Rubocop for development

### From FPHS - PR #763 - 2025-11-27

- [Fixed] Redcap project updating dynamic model removes any existing settings in the _configurations - fixes #675

### From FPHS - PR #762 - 2025-11-27

- [Fixed] small issue in parallel_tests script
- [Fixed] Reference Data for Tables can't view users table - fixes #752

### From FPHS - PR #761 - 2025-11-27

- [Fixed] Date Time edit field incorrectly implemented - fixes #760

### From FPHS - PR #758 - 2025-11-26

- [Added] dynamic definition show_if configuration allows affected fields to be defined using regex patterns - resolves #296 and #612 (with extra configurations)

### From FPHS - PR #757 - 2025-11-26

- [Added] correct viewing of Redcap fields with multiple data collection instruments, relying on option types - resolves #606

### From FPHS - PR #756 - 2025-11-26

- [Added] Redcap project button to call export_logs and save result as a file to the project filestore container
- [Added] redcap API methods to export_logs form_event_mapping export_field_names - related to #683
- [Added] better logging and exception handling (especially for network errors)

### From FPHS - PR #755 - 2025-11-26

- [Added] more default options
- [Cleaned] code
- [Fixed] typos

### From FPHS - PR #754 - 2025-11-26

- [Experimental] use of Chrome as an optional test browser - relates to #753

### From FPHS - PR #749 - 2025-11-22

- [Fixed] Dynamic models - caption_before with escaped characters break the_comments: fields: and cause YAML issues - fixes #676

### From Viva - PR #748 - 1015-11-21

- [Changed] precedence of selecting SMTP TLS or STARTTLS

### From Viva - PR #747 - 2025-11-20

- [Changed] user email notifications to perform in the background
- [Fixed] SMTP timeout too low for SES

## [9.32.0] - 2025-11-20

### From Viva - PR #746 - 2025-11-20

- [Fixed] mail misconfiguration exception with `mail` new gem version - fixes #745

### From Viva - PR #743 - 2025-11-19

- [Fixed] big_select fields don't trigger show_if field rules - fixes #742
- [Fixed] show_ifs in admin sample of dynamic model

### From Viva - PR #741 - 2025-11-19

- [Added] logging of backtrace to support errors - related to #733

Fixed brakeman allow list

### From Viva - PR #739 - 2025-11-18

- [Fixed] user profile user details (activity log) tab doesn't show any content - fixes #735
- [Added] logging info for failing calc_if
- [Added] blank option to admin filters
- [Fixed] inability to import  - related to #90

Fixed reporting multiple failures

### From Viva - PR #737 - 2025-11-18

- [Added] diff of changes for results of app imports - resolves #736

### From Viva - PR #734 - 2025-11-17

- [Added] option to log access authorization information for a request (param `_log_access=true`) - resolves #733

### From FPHS - PR #732 - 2025-11-17

- [Fixed] error handling from Redcap client requests - fixes  #731

### From Viva - PR #730 - 2025-11-13

- [Changed] reporting of parallel test failures - retesting needs to save results - resolves #729

### From Viva - PR #728 - 2025-11-13

- [Fixed] issues with activity log references showing dynamic models, based on a regression due to option types
- [Fixed] issue with reports embedded by handlebars
- [Fixed] Portal pages relying on common_page_template_results partial are not showing the actual content - fixes #725

### From FPHS - PR #727 - 2025-11-13

- [Fixed] saving a dynamic definition with `dialog_before: some string` causes an error - fixes #726

### From FPHS - PR #724 - 2025-10-13

- [Fixed] page layouts (/content/...) requests to honor user_app_type URL param - fixes #723

### From FPHS - PR #722 - 2025-10-12

- [Added] an dynamic definition option to allow the default option type name to be set to a value other than "default" - resolves #721

### From Viva - PR #720 - 2025-10-12

- [Added] tests for alternative option type field in dynamic definition - resolves #719

### From Viva - PR #718 - 2025-11-10

- [Added] support for selecting templates with option types - resolves #605
  - [Added] use of option type request parameters and record fields
  - [Changed] handling of UI templates to support option types for dynamic definition forms
  - [Added] base_route_... information to support consistent paths in URLs and templates
- [Added] _override,_merge_default and_merge_override options to dyanmic definitions - resolves #326
- [Added] logging to help debug
- [Added] initial documentation of the UI templates
- [Fixed] setup of test apps
- [Fixed] issue parsing extra options YAML
- [Fixed] specs

### From FPHS - PR #716 - 2025-11-04

- [Fixed] issue with show_if fields from actiivity logs

## [9.31.0] - 2025-10-30

- [Fixed] mail misconfiguration exception with `mail` new gem version - fixes #745

## [9.31.8] - 2025-11-19

- [Updated] gems for broken `mail` gem - references #745

## [9.31.7] - 2025-11-19

## [9.31.6] - 2025-11-19

## [9.31.5] - 2025-11-19

### From Viva - PR #743 - 2025-11-19

- [Fixed] big_select fields don't trigger show_if field rules - fixes #742
- [Fixed] show_ifs in admin sample of dynamic model

### From Viva - PR #741 - 2025-11-19

- [Added] logging of backtrace to support errors - related to #733

## [9.31.4] - 2025-11-18

### From Viva - PR #739 - 2025-11-18

- [Fixed] user profile user details (activity log) tab doesn't show any content - fixes #735
- [Added] logging info for failing calc_if
- [Added] blank option to admin filters
- [Fixed] inability to import  - related to #90

### From Viva - PR #737 - 2025-11-18

- [Added] diff of changes for results of app imports - resolves #736

### From Viva - PR #734 - 2025-11-17

- [Added] option to log access authorization information for a request (param `_log_access=true`) - resolves #733

## [9.31.3] - 2025-11-13

- [Fixed] saving a dynamic definition with `dialog_before: some string` causes an error - fixes #726
- [Fixed] Portal pages relying on common_page_template_results partial are not showing the actual content - fixes #725
- [Fixed] issue with reports embedded by handlebars
- [Fixed] issues with activity log references showing dynamic models, based on a regression due to option types

## [9.31.2] - 2025-11-12

### From FPHS - PR #722 - 2025-10-12

- [Added] an dynamic definition option to allow the default option type name to be set to a value other than "default" - resolves #721

### From Viva - PR #720 - 2025-10-12

- [Added] tests for alternative option type field in dynamic definition - resolves #719

## [9.31.1] - 2025-11-10

### From Viva - PR #718 - 2025-11-10

- [Added] support for selecting templates with option types - resolves #605
  - [Added] use of option type request parameters and record fields
  - [Changed] handling of UI templates to support option types for dynamic definition forms
  - [Added] base_route_... information to support consistent paths in URLs and templates
- [Added] _override,_merge_default and_merge_override options to dyanmic definitions - resolves #326
- [Added] logging to help debug
- [Added] initial documentation of the UI templates
- [Fixed] setup of test apps
- [Fixed] issue parsing extra options YAML
- [Fixed] specs
- [Updated] gems

### From FPHS - PR #715 - 2025-10-29

- [Fixed] bug checking timed out indicators

### From FPHS - PR #714 - 2025-10-29

- [Changed] Filestore exceptions to inherit from StandardError
- [Fixed] Filestore incorrectly indexing mounted archive folders if they haven't been processed - fixes #713
- [Added] better reporting of Zip "mounter" errors that occur in background processes
- [Changed] "file status" to appear at the top of a Filestore browser

### From FPHS - PR #711 - 2025-10-28

- [Fixed] Filestore adding .__processing__ files to index - fixes #710

### From FPHS - PR #709 - 2025-10-28

- [Fixed] Filestore not indexing files uploaded in a Zip with multiple levels of subdirectories - fixes #704
- [Added] Filestore auto setup of DB stored file records that don't have a corresponding entry - resolves #70
- [Changed] handling and display of archive / unzip errors
- [Fixed] page jumping to top when cancelling a secure view file that can't be viewed
- [Fixed] admin field popover error
- [Fixed] unnecessary attempts to scroll page

### From FPHS - PR #707 - 2025-10-28

- [Changed] Filestore upload multi files - condensed list of uploaded files - resolves #705

### From Viva - PR #703 - 2025-10-23

- [Added] documentation on setting search_path directly on the database user - resolves #577

### From Viva - PR #701 - 2025-10-23

- [Fixed] embedded_record substitution in a placeholder doesn't work (in show mode) - it does above a reference caption - fixes #684

### From Viva - PR #700 - 2025-10-23

- [Fixed] documentation for preset_fields and others that use with_results - fixes #698

### From Viva - PR #699 - 2025-10-23

- [Added] feedback to help with misconfigurations
- [Fixed] disabling a dynamic model shows error `private method 'select' called for nil` - fixes #680

## [9.30.6] - 2025-10-16

### From FPHS - PR #697 - 2025-10-16

- [Added] `redirect_to_url` as a `save_action.on_...` option - resolves #696
- [Fixed] `save_action.on_...` doesn't work if there is a `label:` defined for the save button - fixes #695

## [9.30.5] - 2025-10-14

- [Fixed] potential error returning raw results and JSON parsed results by updating the "redcap" gem

### From FPHS - PR #694 - 2025-10-14

- [Fixed] small documentation issues
- [Fixed] potential error returning raw results and JSON parsed results by updating the "redcap" gem
- [Added] ability for embedded reports to run within models for backend substitutions to function
- [Added] environment variables to control spec webmocks and Redcap API mocks
- [Changed] presentation of report admin index
- [Fixed] master list "search" button can't be hidden with the current hide_search_button option - fixes #686
- [Added] url search attributes section to report admin info block
- [Fixes] report_type=search and searchable checkbox seem to affect the display of the master results block differently - fixes #685
- [Added] extra documentation for report admin
- [Changed] handling of field popovers to allow markdown formatting
- [Changed] admin panel display to hide navbar search fields

### From FPHS - PR #693 - 2025-10-14

- [Fixed] user access control incorrectly checks for existence - fixes #692

### From FPHS - PR #690 - 2025-10-14

- [Fixed] view_sql and default YAML anchors fail - fixed #689

### From FPHS - PR #688 - 2025-10-07

- [Fixed] Redcap import_records returning an array with a single string - fixes #687

### From FPHS - PR #682 - 2025-09-18

- [Fixed] valid_if condition with `masters: {}` causes error - fixes #681

### From Viva - 2025-09-09

- [Fixed] release_and_build.sh to correctly set the default ruby version

### From FPHS - PR #668 - 2025-09-09

- [Fixed] AJAX errors reported to users
- [Fixed] potential error if dynamic model has no primary key
- [Fixed] error where errors reported through flash are too large and break max header length for reverse proxy
- [Fixed] errors that prevented report attribute configuration editor from loading - fixes #667
- [Changed] build scripts to correctly use the Ruby version from the codebase.
- [Fixed] bad creation of CHANGELOG entries

### From FPHS - PR #664 - 2025-09-03

- [Fixed] select-as-radio-buttons breaking show_ifs when other fields are also involved in the conditions - fixes #663

### From FPHS - PR #662 - 2025-09-03

- [Added] broader checks for embedded item def versions

### From FPHS - PR #661 - 2025-09-03

- [Fixed] versioned activity logs breaking the versions of embedded items - fixes #660

### From Viva - PR #659 - 2025-09-02

- [Fixed] get_changelog_entries_from_git.sh incorrectly lists commits - fixes #658

### Local Change - 2025-09-02

- [Changed] details on committing merge for latest release

## [9.29.0] - 2025-09-02

### From Viva - PR #657 - 2025-09-02

- [Fixed] MIME type comparisons for previewing files in filestore - fixes #656

### From Viva - PR #655 - 2025-09-02

- [Added] better styling to make it more obvious which report tab has been selected - fixes #654

## [9.28.0] - 2025-08-21

### From Viva - PR #646 - 2025-08-21

- [Fixed] comparison of user_role in user access controls when role names are '' and nil
- [Fixed] conditional calculation failures shouldn't show so much info to end users - fixes #643
- [Changed] exception handling for dynamic def route generation
- [Changed] dynamic def config triggers to avoid running if the option configs are invalid
- [Fixed] failing to start server if dynamic definition yaml options contain error during parse - fixes #633
- [Changed] reporting of option config errors and report any errors during cleaning with a separate exception class
- [Changed] option error display in admin panels
- [Added] new exception types specific to options
- [Added] ability to report yaml parsing issues directly in admin panel
- [Changed] handling of dynamic definition configuration setup to avoid unnecessary exceptions

### From Viva - PR #645 - 2025-08-21

- [Fixed] Admin users without specific capabilities shouldn't be shown links in app type components sidebar or page - fixes #636
- [Fixed] changes to user or admin not reflected in cached partials

## [9.27.0] - 2025-08-20

### From FPHS - PR #642 - 2025-08-20

- [Added] script to get CHANGELOG.md entries from git and fixed the release_and_build.sh script to use it - fixes #641

### From FPHS - PR #640 - 2025-08-20

- [Added] markup classes to debug table editing permission issues
- [Fixed] 'as-radio-buttons' class on a select field failing to operate or initialize show_ifs if multiple forms with this option were showing - fixes #631
- [Fixed] missing space in jasmine tests script
- [Fixed] Redcap fields with a single checkbox and no choice label show a humanized field name, which is wrong - fixes #629
- [Added] cache of table header and comments to speed up reports
- [Changed] parallel_test retries listing
- [Fixed] excessive time to retrieve client requests in large tables. We could consider indexing on updated_at in the future. Fixes #624
- [Changes] to support debugging
- [Fixed] Redcap ref-data app change link
- [Changed] short string backtrace to help specs
- [Fixed] many access control errors in specs and added better logging to support this
- [Fixed] Time and other formatter bugs in JS - fixes #622
- [Fixed] time fieldsin form (show mode) not being handled correctly - fixes #622 - fixes #623
- [Fixed] submit buttons on registration and password change not graying out - fixes #638
- [Added] new reloading of routes after creating or disabling dynamic definitions
- [Fixes] _fpa.js reports "An error occurred." for 502 and 503 errors, for which we should tell the user there was an error connecting to the server. - fixes #628
- [Added] HTML markup for autocomplete in new password and 2FA forms - fixes #592
- [Added] versions tab to activity log definition panel, like we have with dynamic models - resolves #615
- [Fixed] a "New User Registered" email is sent when creating a ...@template user - fixes #596
- [Fixed] message notification content not showing in message notifications admin panel
- [Changed] release script to produce a better CHANGELOG update from git

## [9.26.0] - 2025-08-18

- [Updated] gems to address CVE-2025-24293

### From Viva - PR #637 - 2025-08-18

- [Fixed] create_master with move_this breaks if there is an embedded item that has no master association and provide new specs - fixes #635
- [Changed] position of `self.table_name` assignment to avoid breakages in included modules

## [9.26.0] - 2025-08-18

- [Built] and tested release-ready version '9.25.0' - dev repo
- [Fixed] `{{#is array "includes" 'val'}}` failing because it treats array as a string - fixes #618
- [Fixed] Redcap integration handling multiple choice fields "incorrectly" with choices containing uppercase characters - fixes #625
- [Updated] gems

## [9.25.0] - 2025-07-29

- [Updated] gems

## [9.24.0] - 2025-07-29

- [Updated] Correctly updated Ruby version to version 3.4.5
- [Updated] gems

## [9.23.0] - 2025-07-29

- [Updated] Ruby version to version 3.4.5
- [Updated] gems

NOTE: It is essential to run `export PATH=/usr/lib/postgresql/15/bin:${PATH}` in development environments that include Postgres v17, to avoid issues when connecting to the database with the new gem pg v1.6.0.

### From FPHS - PR #610 - 2025-07-02

- [Added] missing documentation for use_plain_attribute_names report option - resolves #2

### From Viva - PR #602 - 2025-07-08

- [Fixed] extra options references.filter_by to document that a Hash must return_value, and to test it works if there are no other conditions - fixes #601
- [Reverted] change returning true result on return_value, to avoid unexpected issues in current conditions

## [9.22.0] - 2025-07-08

### From FPHS - PR #600 - 2025-07-07

- [Fixed] nfs_apps_list.txt not being written on startup of server and doesn't recognize the NFS mountpoint - fixes #598

### From FPHS - PR #599 - 2025-07-07

- [Fixed] importing an app with view definitions, if the SQL failed, future migrations just wouldn't run - fixes #597

### From FPHS - PR #594 - 2025-07-02

- [Added] evaluation of active_values field option, much like preset_value does, but repeats evaluation even if the instance has been persisted - resolves #593

### From FPHS - PR #591 - 2025-07-02

- [Fixed] secure view not being set up correctly
- [Fixed] download_field_file not finding the correct project if there are duplicates
- [Added] redcap_event_name to the substitution list not to titleize
- [Added] the ability to bypass container access check for a container in the admin master (-2) if the user has the appropriate role
- [Fixed] redcap api calls to get survey_links and import records, plus added better logging if there's a failure
- [Changed] model reference filter_by to allow hash lookup of values and triple curly substitutions
- [Fixed] failed json edit field causing infinite recursion
- [Added] more information logged when there is a failed extract of archived files
- [Added] better error reporting if the run_jobs_as_user setting in redcap project admin configuration is not found
- [Added] better error for missing settings in Encryption
- [Added] check during initialization for encryption settings

### From FPHS - PR #588 - 2025-06-30

- [Added] a mechanism to copy all the sub_process, protocol_event tree from one protocol to another - resolves #578

### From FPHS - PR #587 - 2025-06-30

- [Added] real lookup of report table id field for better editing - fixes #576

### From FPHS - PR #586 - 2025-06-30

- [Changed] selecting a new app in the app type selector, so that the user is redirected to the configured home page, not masters/search - resolves #575

### From FPHS - PR #581 - 2025-06-30

- [Documented] why conditions have a missing association with no_masters - resolves #580

### From FPHS - PR #582 - 2025-06-30

- [Fixed] failure to read nfs_apps_list.txt file during initialization breaks the server - fixes #579 (also requires EB config changes outside this repo)
- [Fixed] logging of calc_if errors to ensure the actual error is available

## [9.21.0] - 2025-06-25

### From Viva - PR #574 - 2025-06-25

- [Added] auto population of release CHANGELOG from git commits, if the "unreleased" section is empty - resolves #573

### From Viva - PR #572 - 2025-06-25

- [Changed] handling of table comments to avoid broken migrations - fixes #571
- [Changed] setting of schema name causing it to be blanked out - fixes #397
- [Added] Postgres maximum identifier length to settings and use this to fix reference view names
- [Fixed] incorrect reporting of missing schema when the table or view doesn't even exist
- [Added] automatic retest of failed specs
- [Changed] activity log admin activities list to improve usability

### From Viva - PR #570 - 2025-06-24

- [Fixed] save buttons overlapping with options editor in dynamic model and external identifier admin - fixes #520
- [Fixed] no field_options being passed to field name_ends_with_year
- [Fixed] field_configs not picking up the values from standalone fields, and presenting weird captions (already "cleaned")
- [Added] `field_has_no_tags` default options definition

### From FPHS - PR #569 - 2025-06-24

- [Added] admin components menu and dynamic def reference links open individual items in edit mode automatically - resolves #568

## [9.20.0] - 2025-06-24

### From FPHS - PR #567 - 2025-06-24

- [Added] js-base64 javascript package to handle non ASCII characters in admin options, then force to UTF-8 encoding when decoding on the server
- [Changed] handling of error logging to ensure a sensible message is always returned to the front end

## [9.19.0] - 2025-06-24

- [Updated] gems (important - to include newest Redcap gem)

### From FPHS - PR #563 - 2025-06-24

- [Fixed] failed reporting of Redcap job failures by allowing empty data in notifications
- [Added] form field for retrieving Redcap files with a simpler path that redirects to the full nfs_store request - resolves #560
- [Fixed] Redcap files can't be pulled for longitudinal projects with redcap_event_name field - fixes #561
- [Added] longitudinal fields to redcap requests if the the project is set to is_longitudinal - resolves #559

### From FPHS - PR #562 - 2025-06-24

- [Added] longitudinal fields to Redcap requests if the the project is set to is_longitudinal - resolves #559

### From FPHS - PR #565 - 2024-06-24

- [Added] ability to set default zoom and available zoom factors for secure viewer in app configurations
- [Fixed] issue matching files to MIME types, causing error previewing documents or images in secure viewer - fixes #556

### From FPHS - PR #564 - 2024-06-24

- [Fixed] external-links panel not showing even if enabled for a user - fixes #557

## [9.18.0] - 2025-06-17

### From FPHS - PR #555 - 2025-06-17

- [Fixed] spec tests
- [Changed] logging on job failure
- [Added] better logging and attempt to set current_role_name if not set when indexing archived files in NFS Store - fixes #547

### From FPHS - PR #554 - 2025-06-17

- [Fixed] missing form change to allow for base64 encoding of fields

### From FPHS - PR 553 - 2025-06-17

- [Added] initialization of admin attributes based on default_options... app configurations
- [Added] default_schema_name to not be titleized and logic to prevent plain triple curly substitution from crashing if none are in the content
- [Added] environment variable SEED_ONLY to control list of seeds to run
- [Added] seeds for app_configurations
- [Changed] handling of default_schema_name and added default_category
- [Added] app configurations for default options...
- [Changed] app configurations so app type is not required
- [Added] admin filter on blank app type
- [Fixed] Web Application Firewall blocks definition of dynamic models (and config libraries) with view_sql in admin console - it assumes the SQL is an attempt at SQL injection - fixes #545

### From FPHS - PR #552 - 2025-06-17

- [Fixed] error reported when clicking between search tabs with certain reports - fixes #546

### From FPHS - PR #551 - 2025-06-17

- [Fixed] Web Application Firewall (WAF) blocks definition of reports in admin console - it assumes the SQL is an attempt at SQL injection - fixes #527

### From FPHS - PR #550 - 2025-06-17

- [Added] base_master_segment to support URL generation
- [Changed] handling of exceptions if a master is not set when it should be
- [Fixed] report failing when an embedded_block is used and the data to form the URL varies based on the resource being queried
- [Added] extra attributes for SQL substitutions (and report criteria / descriptions)
- [Changed] handling of substitutions into report descriptions to use more details related to the table being accessed
- [Added] show_if configuration to search criteria field, allowing it to be conditionally shown
- [Fixed] disappearing error notice when areport is run automatically when saving the definition in the admin panel

### From FPHS - PR #549 - 2025-06-17

- [Fixed] when attempting to disable a page layout configuration, it still checks for uniqueness of the name - fixes #524
- [Fixed] add_tracker setting event_date from a condition reference doesn't work - fixes #542
- [Fixed] Activity subprocess for activity logs is not created as new protocols are added - fixes #543

### From FPHS - PR #548 - 2025-06-17

- [Fixed] regression in PR #537 when providing additional logging information related to failed calculated conditions

### From FPHS - PR #541 - 2025-06-10

- [Added] return failure value from parallel_specs.sh - resolves #535

### From FPHS - PR #540 - 2025-06-10

- [Added] App Type import "lock" to prevent multiple transactions from running simultaneously - fixes #528

### From FPHS - PR #539 - 2025-06-10

- [Fixed] user roles failing to be created (copied) if template has duplicates with the same name - fixes #531

### From FPHS - PR #538 - 2025-06-10

- [Fixed] substitution error when an association returns no results and subsequent regression - fixes #526 and  #534

### From FPHS - PR #537 - 2025-06-10

- [Added] has_not_created_activity
- [Fixed] has_created_activity when nested in all:, any:, etc - fixes #532
- [Changed] reporting of errors in conditional calculations to make debugging easier
- [Added] more details to failing archive_retrieval_path if no role is set
- [Fixed] checking for {{template_block...}} in app types breaks if description is NULL - fixes #533

## [9.17.0] - 2025-05-22

### From FPHS - PR #519 - 2025-05-22

- [Changed] handling of extra options YAML to clean it when a dynamic definition is saved, and to make exports unlimited line width to simplify markup
- [Added] extra options simplified condition `has_created_activity: <extra_log_type>` to simplify configurations - closes #518
- [Fixed] `<<: *never_creatable` missing from default options
- [Fixed] "category" not being passed when doing a perform_action "new" for a message_notification - fixes #517
- [Fixed] page layout initial_show option not working, even if no open_panels option is set - fixes #516
- [Changed] styling of text areas in admin forms to make them wider
- [Fixed] configuration notices appearing in an accordian that doesn't operate correctly when viewing app type components - fixes #515
- [Fixed] dashboard block showing "The requested resource was not found" when no report or resource actually configured - fixes #514

## [9.16.1] - 2025-05-20

- [Build] FPHS version

## [9.16.0] - 2025-05-20

### From FPHS - PR #513 - 2025-05-20

- [Fixed] bug setting fields and field_list definitions incorrectly, breaking the intent of the configurations

## [9.15.0] - 2025-05-20

### From FPHS - PR #512 - 2025-05-20

- [Fixed] label on "add field" input in dynamic model definer
- [Changed] styling of form list definer "delete field" block
- [Added] error check on field_configs setting
- [Added] expanding of all label, caption and dialog definitions in dynamic model field definer
- [Added] field details in dynamic model admin info panel
- [Fixed] expandable text areas and blocks in admin forms and index lists
- [Changed] browser cache time for report admin search attrs
- [Added] better cache handling of page templates
- [Added] more conditions to show_if when using `condition` option
- [Added] `select as-radio-buttons` class to convert select field to radio buttons
- [Added] ability to pass "perform_actions" attribute to admin requests, allowing new and edit actions to open directly the form
- [Added] passing class to select field allows field_options.class to be used for `field_type: select_...`
- [Fixed] issue starting javascript tests
- [Added] consolidated list of 'field_configs' in extra options, to improve configurations - resolves #510

### From FPHS - PR #511 - 2025-05-13

- [Added] standard extra options for is_blank and is_not_blank conditions
- [Fixed] templates referenced in report descriptions not included in app type export - fixes #341
- [Fixed] external ids panel not reorganizing the blocks as expected - fixes #508
- [Fixed] missing big select field for admin panel app configurations name
- [Fixed] default panels not showing based on comma separated list of panels in application configurations
- [Fixed] user access control panel in activity log showing too many items due to bad LIKE handling in SQL
- [Fixed] search attributes dynamic load taking ages to complete on each page refresh - fixes #509
- [Fixed] search attributes panel disabling fields unnecessarily

### From FPHS - 2025-05-08

- [Updated] brakeman whitelist for report descriptions

### From FPHS - PR #506 - 2025-05-08

- [Added] dynamic loading of the search attribute definer in report admin, to speed up opening of report definitions
- [Fixed] report_type filter missing and causing errors when embedding in admin info blocks
- [Fixed] unnecessary cache around user access controls block that loads dynamically
- [Fixed] bad double curly substitutions in report description causing exception that can't be fixed in the report admin editor - fixes #327

### From FPHS - PR #505 - 2025-05-07

- [Added] script to call setup_filestore_app.sh based on the nfs container status file created during appserver startup
- [Changed] setup of filestore app directories to be idempotent
- [Changed] script to restart app server to avoid unnecessary error messages on non-EC2 servers
- [Added] a file to indicate if filestore app type containers need to be created

### From FPHS - PR #504 - 2025-05-07

- [Changed] reporting of new / changed app type import items if only updated_at and admin_id fields have changed - fixes #371
- [Changed] naming of activity log history trigger naming to avoid truncation
- [Changed] reverse migration drops to avoid failures

### From FPHS - PR #503 - 2025-05-05

- [Fixed] raising of exception if attempting to create a filestore container with incomplete information - fixes #502

## [9.13.1] - 2025-04-30

### From Viva - PR #501 - 2025-04-29

- [Fixed] brakeman and bunder-audit to write output to created temp files - fixes #500

### From Viva - PR #499 - 2025-04-29

## [9.13.3] - 2025-04-29

### From Viva - PR #498 - 2025-04-29

- [Added] ability for dynamic models to use tables without user_id field for updates and creates - fixes #496

### From Viva - PR #497 - 2025-04-29

- [Added] open_panels calculation for masters based on substitutions
- [Added] documentation of app configurations
- [Added] markup to show empty results - to assist in styling
- [Fixed] handlebars helper for includes and server substitutions to match

## [9.13.2] - 2025-04-23

- [Fixed] issue from Rails 7 upgrade where errors from embedded item are not merged into the parent (or master) correctly

## [9.13.1] - 2025-04-21

### From Viva - PR #493 - 2025-04-21

- [Changed] selection of RUBY_V to use the source code version

## [9.13.0] - 2025-04-21

### From FPHS - PR #491 - 2025-04-21

- [Added] links for JSON, text and CSV to admin panel to simplify testing
- [Added] report admin json_options Added template option to report admin plain_text_options for substitution into each row
- [Fixed] admin report preview search form to always show a "run" button
- [Added] report view_options.use_plain_attribute_names to use simple attributes if search_attrs[] is not present
- [Added] ability for report admin to force view of a table, rather than the configured type in report options

### From FPHS - PR #489 - 2025-04-16

- [Changed] arrangement of report admin page for ease of use when editing SQL

### From FPHS - PR #487 - 2025-04-15

- [Changed] the creation of migration triggers onto history to avoid foreign keys blocking common DBA actions - fixes #394
- [Added] an actions tab to the external identifier definitions form to tie in record counts and generation actions
- [Added] ability to reset the estimated record count for dynamic definitions (used by external identifiers initially)
- [Fixed] external identifier table triggers to update history tables, which were not being created - fixes #393

### From FPHS - PR #486 - 2025-04-15

- [Fixed] significant delays when opening report definitions - fixes #328
- [Added] embedded report within definition block to simplify report testing
- [Fixed] updating of a report definition form and the report list below to avoid confusing users or breaking the "updated at" check
- [Fixed] scrolling issues for report admin forms

### From FPHS - PR #485 - 2025-04-15

- [Added] dynamic model link to CSV table generator - fixes #484
- [Removed] initializer requiring csv directly - including csv as a gem no longer needs this

### From FPHS - #PR 481 - 2025-04-14

- [Added] report option for plain text response, with various "markup" options - resolves #480

## [9.12.1] - 2025-04-09

### From FPHS - PR #479 - 2025-04-09

- [Fixed] attempt to require removed do_nothing_logger in production - fixes #478

### From FPHS - PR #477 - 2025-04-09

- [Fixed] specs to get a clean parallel test run - fixes #476

### From FPHS - PR #475 - 2025-04-09

- [Removed] DoNothingLogger implementation and simplified initializer configuration to use a nil logger

### From FPHS - PR #473 - 2025-04-09

NOTE: New Ruby version will require AWS Elastic Beanstalk, test and dev environments to be updated to 3.4.2

- [Updated] Ruby version to 3.4 - fixes #472
- [Fixed] failing specs associated with new Ruby version

### From Viva - PR #471 -  2025-04-07

- [Added] option to allow empty Unreleased section in release and build

## [9.12.0] - 2025-04-07

### From FPHS - PR #470 - 2025-01-20

- [Fixed] migration script  to use `bundle exec`

### From FPHS - PR #469 - 2025-02-12

- [Fixed] error using embed with simple use of 'embedded_item' or 'dynamic_model__some_recs'

### From FPHS - PR #468 - 2025-01-27

NOTE: Requires a database migration on upgrade

- [Changed] user and admin models for the new otp secret
- [Added] DB migrations to bring user and admin history tables and triggers up to date
- [Updated] schema dump

### From FPHS - PR #467 - 2025-02-25

- [Added] ability to copy roles from a user to a target user that already has roles

## From FPHS - PR #466 - 2025-02-12

- [Added] add-activity-button-<extra log type> as a link hash option for clicking activity log buttons in the current panel header
- [Changed] add-activity-button-<extra log type> link hash to show as disabled if the panel activity button is not available
- [Fixed] `{{#is tag '===' 'string literal'}}` comparison due to bad quote matching
- [Fixed] broken view_with_formats for certain strings

### From FPHS - PR #465 - 2025-02-18

- [Fixed] broken `references:` configuration when specifying without_reference
- [Changed] enforcement of ref-data app for admins when viewing Redcap projects
- [Fixed] error comparing equality in `{{#is...}}` substitutions
- [Added] clearer styling for loading panels
- [Fixed] jump to linked item causing errors when passed a jQuery object

### From FPHS - PR #464 - 2025-02-18

- [Fixed] broken lookups on preset field values in embedded items, and avoid unnecessary initialization of models
- [Fixed] error for protocols in activity log related items (such as player contacts in phone logs)

### From FPHS - PR #463 - 2025-04-02

- [Added] details to reference definition_resources in the activity log admin info and default options in the documentation
- [Fixed] unusual filestore directory issues during testing in parallel
- [Added] details about Firefox and geckodriver
- [Fixed] failing spec tests
- [Added] logging to explain defaults selected for db migration schema

### From FPHS - PR #462 -  2025-04-02

- [Fixed] issues with dynamic model default configs with missing attributes
- [Added] details to app type status for extra setup required
- [Added] better reporting of issues sorting references
- [Changed] handling of default labels for report criteria if no label is specified
- [Fixed] handling of the dry run and skip failures combination in app type imports - fixes #301
- [Fixed] app type import creating default *app* user access controls in the matching user's current app. Now switches the app to the new app type on import
- [Changed] handling of migration errors that include syntax errors
- [Changed] activity log trigger
- [Added] checking of migration table name
- [Fixed] bad table naming when creating default embed
- [Changed] maximum results for Redcap client request log

### From Viva - PR #461 - 2025-04-02

- [Changed] cleanup of assets to avoid needing a DB connection in release_and_build.sh script

### From FPHS - PR #460 - 2025-03-18

- [Fixed] prepending _comments in extra options

### From FPHS - PR #457 - 2025-02-24

- [Added] save trigger for redcap requests, allowing save and batch triggers to perform any implemented Redcap action
- [Fixed] handling of associate_master_through_external_id when using a field that is not redcap_survey_identifier

### From FPHS - PR #456 - 2025-02-25

- [Added] `iso8601_datetime` and `redcap_date` tag formatters

### From Viva - PR #454 - 2025-01-30

- [Fixed] import CSV bugs

### From Viva - PR #453 - 2025-01-30

- [Fixed] log filename breaking Rails server log search

## [9.2.1] - 2025-01-30

### From FPHS - PR #452 - 2025-01-30

- [Fixed] rubocop line length cop for new naming

### From FPHS - PR #451 - 2025-01-30

- [Added] simplified `with: <String>` option to define item to use in a trigger

### From FPHS - PR #450 - 2025-01-29

- [Added] ability to define config_trigger.on_define as an array, allowing multiple similar configurations
   to be added (for example user access controls) for each activity

### From FPHS - PR #449 - 2025-01-29

- [Added] previously default gems to Gemfile Fixed rubocop stub

### From FPHS - PR #448 - 2025-01-29

- [Fixed] edit field labels and formats for external id attribute
- [Changed] handling of expandable blocks to expand if caret clicked
- [Fixed] multiple radio buttons with same field name conflict
- [Fixed] crash of foreign key through external identifier

### From FPHS - PR #447 - 2025-01-29

- [Changed] migration timeout to allow for large model changes

### From FPHS - PR #444 - 2025-01-27

- [Fixed] error handling `{{else}}` in front end evaluation of substitutions (such as show_if)
- [Fixed] missing user_id in forms passing to data for show_if

## [9.1.1] - 2025-01-20

### From FPHS - # PR 443 - 2025-01-20

- [Fixed] issue with standard definitions for extra options
- [Fixed] the use of masters resource name when using no_masters to lookup a crosswalk identifier
- [Fixed] broken log filename in some environments
- [Fixed] Zeus Advanced Search protocol not having a sub process query fails with SQL syntax error - fixes #438
- [Added] sample form to external identifiers admin panel
- [Added] fields sorter to external identifiers admin panel
- [Added] resource name value to external identifiers admin panel
- [Fixed] report  count button not working - fixes #439
- [Added] link from external identifier details panel to pregenerated search report - fixes #377
- [Changed] ordering of external identifier master panel based on size - fixes #390
- [Fixed] incorrect URL for editing file classification record
- [Fixed] error running notify after uploading files
- [Added] save_trigger_results to notify
- [Fixed] spring stop in parallel test
- [Fixed] admin forms with dependent fields not setting up on load
- [Fixed] admin forms display
- [Fixed] tracker, protocol column shows with titelized case, rather than original entry - fixes #433
- [Changed] use of `@import` in SCSS files to use `@use` without a namespace - fixes #436
- [Fixed] Zeus toolbar search broken after upgrade to Rails 7 - fixes #437
- [Fixed] a crosswalk error when requested master records don't match
- [Fixed] incorrect documentation for tracker sorter options
- [Fixed] failure of table lists to be rendered
- [Fixed] dynamic options standard definitions not being preprended correctly
- [Fixed] handling of legacy otp for 2FA

### From FPHS - PR #442 - 2025-01-07

__NOTE:__ DB migration required

- [Changed] handling of SECRET_KEY_BASE and other non-production credentials to use Rails standard environment variable and credentials rather than secrets
- [Added] USEVER variable handling for batch use of release_and_build.sh
- [Fixed] specs for more info on failures and to fix inline activity log configurations
- [Updated] schema for Postgres v15
- [Added] new otp_secret field for devise-two-factor gem
- [Fixed] tracker_histories association
- [Changed] message when failing to load a dynamic model during reload
- [Fixed] dynamic migrations
- [Updated] sprockets gem to v4
- [Changed] browser check to use new Rails support for browser version checking
- [Updated] configs for Rails 7
- [Updated] gems to Rails 7.2 via 7.0 and 7.1
- [Fixed] admin panel email field styling
- [Changed] login issues text to simplify it for users

### From FPHS - PR #441 - 2024-12-23

- [Fixed] standard definition loading
- [Fixed] position handling to avoid unnecessary recursion Fixed specs to account for admin panels filtering out disabled items correctly
- [Fixed] protocol / subprocess / event issues Fixed bad styling in admin panels

### From FPHS - PR #430 - 2024-12-19

- [Fixed] inconsistency in labelling protocols / sub processes / events for admin
- [Added] DB table access information for protocols / sub processes / events to help
- [Added] sub process and protocol event help docs (pointing back to protocol doc)

### From FPHS - PR #429 - 2024-12-19

- [Fixed] admin panels for protocol / sub process / event to allow more than one item to be added without breaking - fixes #42
- [Added] information to the protocol admin panel to show the protocol ordering configured for the tracker
- [Added] documentation for the configuration of protocols and the hierarchy of protocol / sub process / event

### From FPHS - PR #428 - 2024-12-18

- [Fixed] Can't select a "blank" no access option in user access controls - fixes #424
- [Fixed] admin copy item select shows value, but this isn't actually submitted and the field is really submitted as blank

### From FPHS - PR #427 - 2024-12-18

- [Added] preconfigured yaml placeholders for dynamic definition options to simplify configurations
- [Added] click on activity list item to auto select it in the sample forms
- [Added] user access control information to each activity list item

### From FPHS - PR #426 - 2024-12-18

- [Fixed] e-signature form captions don't handle substitutions - fixes #425

### From FPHS - PR #421 - 2024-12-12

- [Added] nested embed and references sections under activity list items
- [Fixed] Admin reports panel add or edit report very slow (now only slow the first time) - fixes #420
- [Changed] ordering of reports admin list
- [Fixed] bad reloading of page layouts admin panel

### From Viva - PR #418 - 2024-12-04

- [Fixed] "created_by_user_id" field showing unnecessarily in edit forms

### From Viva - PR #417 - 2024-12-03

- [Fixed] filestore browser not loading correctly in vertical activity log block

# [8.9.2] - 2024-11-14

- [Build] FPHS version

## [8.9.1] - 2024-11-14

## From FPHS - PR #416 - 2024-11-14

- [Fixed] reloading of index after updating users and admins
- [Added] ability for users to be added by an admin when self registration is allowed

### From FPHS - PR #415 - 2024-11-14

- [Fixed] failing versions list when creating a new dynamic model

### From FPHS - PR #413 - 2024-11-13

- [Fixed] issues from merging recent PRs

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

### Merge pull request #320 from hmsrc/hms-perf

- [Added] exception information to failure mailer
- [Updated] gems
- [Fixed] specs
- [Changed] logging of dynamic definition setup
- [Changed] handling of info and help pages to show a not found for missing library or not authorized access
- [Changed] handling of item flags for new selector caching
- [Changed] handling of selector cache handling and application version to log when changes will affect performance
- [Added] index to tracker_history to improve performance

## [8.6.5] - 2024-05-02

- [Updated] gems
- [Fixed] logging of sensitive params
- [Added] report search field options with the first option implemented for "select from model" drop downs being order: attr: asc|desc
- [Added] action_position option to extra options references configurations to set a creatable reference action button to appear at the top or bottom of the form
- [Added] a report results handler implementation to provide "expand all" link to tree view
- [Changed] form fields to cancel previous request when clicking on a "chosen" select field
- [Fixed] UI error if no match on date time string when converting to locale

### Merge pull request #315 from hmsrc/gen-enhancements

- [Added] set_item_flag options to add_flags and remove_flags
- [Fixed] failure to show Redcap project if it is in the process of being

### Merge pull request #314 from hmsrc/clean-log

- [Changed] job error message to be clearer

### Merge pull request #311 from hmsrc/change-save-trigger

- [Added] set_item_flags save trigger to allow flags to be set against an item
- [Added]  return of created masters, items and references from save triggers, so they can be used later
- [Added] logging to show more information when failing to generate real show_if from Redcap definition
- [Changed] external identifiers to allow update from save trigger if currently unassigned

### Merge pull request #310 from hmsrc/fix-job-error

- [Fixed] job failure notifications

### Merge pull request #309 from hmsrc/app-import-errors

- [Fixed] reporting of changes for app imports
- [Changed] handling of user access control configurations to force blank fields to null
- [Changed] app import error backtrace to include only essentials
- [Fixed] reporting of error in app import
- [Changed] reporting of updated configs in app type import when only updated_at timestamp changed
- [Fixed] sidebar help to prevent it breaking simple hash hrefs

## [8.6.4] - 2024-04-03

- [Added] automatically select user date/time preferences based on user browser locale at registration - from pull request #284, issue #135
- [Added] superscript and subscript support to the editor
- [Fixed] editor bugs
- [Fixed] strikethrough support in the editor
- [Fixed] pasting from documents when certain <img> or <a> attributes are missing
- [Added] auto creation of signature document when activity created through create_reference save trigger
- [Changed] styles for e-sign and general forms
- [Changed] e-signatures to allow a plain document to be created for signature - fixes #299
- [Fixed] report not able to show tags in results correctly
- [Fixed] bug trying to singularize configuration keys in e_sign setup

## [8.6.3] - 2024-03-07

- [Fixed] incorrect matching dynamic models on name. Use table_name instead.

## [8.6.2] - 2024-03-06

- [Fixed] parallel tests and specs
- [Fixed] various rspec issues
- [Changed] the naming of Redcap project dynamic models to be more human - fixes #276
- [Fixed] to raise an exception if a nfs store container directory already exists
- [Fixed] Redcap pull updating all records if there are empty `<vars>_chosen_array` fields - fixes #289

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
- [Added] much more consistent handling of resource names with __Resources::Models__
- [Added] user profiles tabs definable using page layout definitions
- [Added] ability to include activity log type as a resource in a page layout definition
- [Added] __add_item_button__ substitution for captions and report headers
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
- [Added] Report results options added __embedded_block__ to show dynamic models as forms from report resutls
- [Added] Contributor field to data dictionary variable records, to accompany target field.
- [Fixed] Template retrieval and post processing templates
- [Changed] Report results table significantly refactored

## [8.0.19] - 2021-11-10

## [8.0.18] - 2021-11-01

- [Added] Add support for Redcap repeating instruments

## Transfer from Harvard @7.4.70 - 2021-10-31

- [Added] Report criteria field type __select_from_model__
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
