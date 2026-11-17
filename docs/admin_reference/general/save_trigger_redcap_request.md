# `redcap_request`
## Make a REDCap API Request

Send a request to a REDCap project via the REDCap API when this trigger fires.

```yaml
!defs(save_triggers_redcap_request_options_defs.yaml)
```

## Available methods

The `method` attribute selects which REDCap API request is made. This includes,
amongst others, `import_records`, `survey_link`, `remove_project_user` and
`import_project_user` - see the patterns below.

### Pattern 1: import_records

Import a record into the project and store the result in `local_data`. The response is a
single-element array (or more if extra `data:` array items are specified) containing the record
id of the stored record. A `record_id` is always required in each `data:` entry, even when
`force_auto_number: true` is set.

```yaml
!defs(save_triggers_redcap_request_pattern_1_import_records_defs.yaml)
```

### Pattern 2: survey_link

Chained after Pattern 1: if the previous record import was successful, get the survey link for
the new record and save it to `data_field`. The target field must set `no_downcase: true` and
`view_original_case: true` in its `field_options`, otherwise the mixed-case URL will be mangled:

```yaml
default:
  field_options:
    econsent_rc_link:
      no_downcase: true
      view_original_case: true
```

```yaml
!defs(save_triggers_redcap_request_pattern_2_survey_link_defs.yaml)
```

### Pattern 3: remove_project_user

Removes one or more users' access from the REDCap project, with an `on_complete` follow-up
request to refresh the cached user list.

- Pass a single `post_data.username`, or an array via `post_data.usernames`, to remove multiple
  users in one request.
- The result stored to `local_data` is the count of users removed, as returned by the REDCap API.
- **Required REDCap privileges**: the REDCap API token's user must have `API Import/Update`,
  `User Rights` (Full Access) and `Delete Records` within the REDCap project, or the API will
  reject the request.
- Removing a user does **not** automatically refresh the project's cached user list (as retrieved
  by `project_users`). Use an `on_complete` hook (shown below) to explicitly call `project_users`
  with `post_data: { force_reload: true }` if the refreshed list is needed immediately.

```yaml
!defs(save_triggers_redcap_request_pattern_3_remove_project_user_defs.yaml)
```

### Pattern 4: import_project_user

Add a user or update their privileges in a REDCap project. If the requesting user has the
`User Rights` privilege, they can add a new user or update an existing user's privileges
(including their own) - for example granting `record_delete` and `api_import` so the user can
delete records and use the REDCap API.

```yaml
!defs(save_triggers_redcap_request_pattern_4_import_project_user_defs.yaml)
```

## Using `redcap_request` in a batch trigger

`redcap_request` can also be configured as a `batch_trigger`, using exactly the
same `redcap_request` configuration shown above. Batch triggers reuse the same
`SaveTriggers::RedcapRequest` handler, so any method available to a save trigger,
including `remove_project_user`, is also available to a batch trigger. This
allows, for example, a scheduled batch job to remove a specific user's access
from a REDCap project without requiring a record to be saved.
