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
data_dictionary_version: random hash
    # do not change - a hash generated internally to 
    # identify whether the data dictionary has changed
```
