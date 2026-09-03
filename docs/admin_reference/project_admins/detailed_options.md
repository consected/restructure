# REDCap Project Transfer: Detailed Options

!defs(project_admin_field_defs.yaml)

---

## Options

Options are set with reasonable defaults when a project is first saved.

```yaml
records_request_options:
  exportSurveyFields: true | false | (blank)
    # The admin must set this value based on the 
    # actual configuration of the REDCap project. 
    # If surveys are enabled for the project, set 
    # this value to **true** otherwise leave it 
    # blank or **false**.
  returnMetadataOnly:
  exportDataAccessGroups:
  returnFormat:
metadata_request_options:
  returnFormat:
data_options:
  add_multi_choice_summary_fields: true | null | (blank)
    # If *true*, Adds an extra array field to the
    # database for checkbox fields, providing
    # a single field summarizing all selected 
    # checkboxes for a single REDCap field.
    # By default (*false* or blank) only the 
    # individual checkbox fields for each option will
    # be added, as 
    # `<field_name>___1`, `<field_name>___2`,...
  handle_deleted_records: value
    # one of
    #   - disable
    #   - ignore
    #   - (blank)
    #   - null
    #   - false
  prefix_dynamic_model_config_library: category name
    # The "<category> <name>" string identifier for a
    # config library to be prefixed to the dynamic
    # model definition whenever it is updated.
    # For example: "redcap test_library"
  associate_master_through_external_identifer: <external identifier> (optional: foreign key name)
    # Specify an external identifier resource name to use to look up the master record each
    # stored record is associated with. By default, "redcap_survey_identifier_id" is used as the
    # foreign key name used to look up the the external id. Optionally specify an alternative field name.
    # When this is specified, and the project is set to `exportSurveyFields: true` then an additional
    # `redcap_survey_identifier_id` field is added to the dynamic model database table, defined as an
    # integer type. This allows it to be correctly joined to integer typed external id fields on other tables.
  set_master_id_using_association: true|false
    # If option `associate_master_through_external_identifer` is set, the ability to retrieve the master record
    # can be used to set a `master_id` field directly on the dynamic model. Setting this option to *true* will
    # add a `master_id` field automatically, and ensure it is set when records are retrieved from REDCap.
    # NOTE: for large datasets that change regularly, this may slow down record retrieval significantly.  
  skip_store_if_no_survey_identifier: true | nil
    # If we are using an association to match a redcap survey identifier to a master record
    # it won't be found if the public survey link was used and no survey identifier was populated.
    # This option allows the record to be skipped when pulling, allowing other records to be retrieved
  run_jobs_as_user: <username>
    # Sets the admin and matching user that will be used to run background jobs, 
    # such as getting project metadata or retrieving records from REDCap.
    # New projects set this to the email address or id in settings `RedcapJobUserEmail`, which may be set by
    # the environment variable `FPHS_RC_JOB_USER_EMAIL` or will default to the setting `BatchUserEmail`.
    # If left blank in earlier projects or explicitly set to blank, the user matching the project's current admin will be used.
  run_jobs_in_app_type: <app type name or id>
    # Sets the app type that will be set on the `run_as_jobs_user`, effectively setting the
    # access controls that authorize actions performed in background jobs such as retrieving records.
    # This avoids an arbitrary app type being set, especially where the dynamic model being stored to has save triggers
    # specified that may depend on access to specific resources.
  metadata_export_cache_time: <seconds> | null
    # Time in seconds to cache REDCap project metadata API responses.
    # When set, repeated requests for project metadata within this time window
    # will return cached results instead of making new API calls.
    # Default: 60 seconds if not specified.
    # Set to null or leave blank to use the default.
  record_export_cache_time: <seconds> | null
    # Time in seconds to cache REDCap record export API responses.
    # When set, repeated requests for records within this time window
    # will return cached results instead of making new API calls.
    # If results are returned from cache, the validate and store steps
    # are skipped since no new data was retrieved.
    # Default: 60 seconds if not specified.
    # Set to null or leave blank to use the default.
  export_only_updated_records: always | manual | scheduled | null
    # Controls whether to use REDCap's dateRangeBegin parameter to only
    # retrieve records that have been created or updated since the last pull.
    # The date is determined by the timestamp of the last successful
    # 'store records' operation for this project (from the client_requests audit log).
    # This ensures we capture when REDCap was actually queried, not when records
    # were stored locally, avoiding gaps if storage is delayed.
    #
    # Values:
    #   - always: Use date range filtering for both manual and scheduled pulls
    #   - manual: Use date range filtering only for manual pulls (admin-triggered)
    #   - scheduled: Use date range filtering only for scheduled pulls (automatic)
    #   - null/blank: Never use date range filtering (retrieve all records)
    #
    # When date range filtering is active, deleted record detection is disabled
    # since only updated records are retrieved, not the full dataset.
    # This can significantly reduce API response times for large projects
    # where only a few records change between pulls.
  server_time_zone: America/New_York
    # The time zone of the REDCap server. Required when using export_only_updated_records
    # if the REDCap server is in a different time zone than UTC.
    # REDCap's dateRangeBegin parameter expects timestamps in the server's local time.
    # This setting converts the calculated date range from UTC to the server's time zone.
    #
    # Use standard IANA time zone identifiers, e.g.:
    #   - America/New_York
    #   - America/Los_Angeles
    #   - Europe/London
    #   - UTC
    #
    # If not set, timestamps are sent as-is (typically UTC).
  continue_on_record_error: true | false | null
    # If true, an exception raised while persisting or triggering a single record
    # during the store step (for example a before_save or after_commit save trigger)
    # is caught and recorded in the job request's errors, allowing the pull to continue
    # processing the remaining records instead of aborting the entire run.
    #
    # - A failure during the before_save phase means the record's transaction was
    #   rolled back and the record was NOT persisted; it is not counted as created
    #   or updated.
    # - A failure during the after_commit phase (e.g. create_reference, add_tracker,
    #   generate_document) means the record WAS already committed; it IS counted as
    #   created or updated, even though the failing trigger's own action did not
    #   complete.
    #
    # Default (false/null): an unhandled exception aborts the entire pull
    # (fail-fast, current behavior).

data_dictionary_version: random hash
    # do not change - a hash generated internally to 
    # identify whether the data dictionary has changed
```
