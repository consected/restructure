# `redcap_request`
## Make a REDCap API Request

Send a request to a REDCap project via the REDCap API when this trigger fires.

```yaml
!defs(save_triggers_redcap_request_options_defs.yaml)
```

## Available methods

The `method` attribute selects which REDCap API request is made. This includes,
amongst others, `import_records`, `survey_link` and `remove_project_user`
(remove a user's access from the project - see `request_3` above).

### `remove_project_user`

Removes one or more users' access from the REDCap project.

- Use `post_data.username` to remove a single user, or `post_data.usernames`
  (an array of usernames) to remove multiple users in a single request.
- The result stored to `local_data` is the count of users removed, as returned
  by the REDCap API.
- **Required REDCap privileges**: the REDCap API token's user must have the
  following privileges within the REDCap project: `API Import/Update`,
  `User Rights` (Full Access) and `Delete Records`. Without these, the REDCap
  API will reject the request.
- Removing a user does **not** automatically refresh the project's cached user
  list (as retrieved by `project_users`). If the refreshed list is needed
  immediately, configure an `on_complete` hook (see `request_3` above) that
  runs a nested `redcap_request` with `method: project_users` and
  `post_data: { force_reload: true }`.

## Using `redcap_request` in a batch trigger

`redcap_request` can also be configured as a `batch_trigger`, using exactly the
same `redcap_request` configuration shown above. Batch triggers reuse the same
`SaveTriggers::RedcapRequest` handler, so any method available to a save trigger,
including `remove_project_user`, is also available to a batch trigger. This
allows, for example, a scheduled batch job to remove a specific user's access
from a REDCap project without requiring a record to be saved.
