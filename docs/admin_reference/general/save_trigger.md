# `save_trigger`

## Save Trigger Actions

Define actions to perform automatically when a record is created, updated, saved, disabled, uploaded, or before saving. Each event key (`on_create`, `on_update`, `on_save`, `on_disable`, `on_upload`, `before_save`) takes an ordered list of trigger tasks. See [Event Keys](#event-keys) for more detail.

```yaml
!defs(extra_options_save_trigger_defs.yaml)
```

## Trigger Types

Each trigger task listed under an event key corresponds to one of the following trigger types:

### Record Operations

| Trigger | Description |
| --- | --- |
| [add_tracker](save_trigger_add_tracker.md) | Add a tracker entry |
| [create_master](save_trigger_create_master.md) | Create a new master record |
| [create_reference](save_trigger_create_reference.md) | Create a reference to another model |
| [reload_this](save_trigger_reload_this.md) | Reload the current record from the database |
| [update_reference](save_trigger_update_reference.md) | Update a referenced record |
| [update_this](save_trigger_update_this.md) | Update fields on the current record |

### Communication & Notification

| Trigger | Description |
| --- | --- |
| [notify](save_trigger_notify.md) | Send an email or SMS notification |
| [pull_emails](save_trigger_pull_emails.md) | Read MIME emails from S3, filesystem, or IMAP and run nested triggers per email |

### User & Access

| Trigger | Description |
| --- | --- |
| [change_user_roles](save_trigger_change_user_roles.md) | Add or remove user roles |
| [set_item_flags](save_trigger_set_item_flags.md) | Set item flags on the current record |

### Files & Documents

| Trigger | Description |
| --- | --- |
| [create_filestore_container](save_trigger_create_filestore_container.md) | Create an NFS filestore container |
| [generate_document](save_trigger_generate_document.md) | Generate a document from a template and store in a filestore container |

### External Integrations

| Trigger | Description |
| --- | --- |
| [pull_external_data](save_trigger_pull_external_data.md) | Pull data from an external HTTP source |
| [redcap_request](save_trigger_redcap_request.md) | Make a REDCap API request |

### Search

| Trigger | Description |
|---|---|
| [full_text_search](save_trigger_full_text_search.md) | Build and persist PostgreSQL `tsvector` full-text search indexes |

### Variables & Results

| Trigger | Description |
| --- | --- |
| [set_save_trigger_results](save_trigger_set_save_trigger_results.md) | Set save trigger result values for use in subsequent triggers |
| [set_variables](save_trigger_set_variables.md) | Set variables for use in subsequent substitutions and triggers |

### Control Flow

| Trigger | Description |
| --- | --- |
| [background](save_trigger_background.md) | Run a set of triggers asynchronously in a background job |
| [case](save_trigger_case.md) | Conditionally branch trigger execution based on a condition |
| [each](save_trigger_each.md) | Iterate over a list and apply a set of triggers for each item |
| [run_batch_trigger](save_trigger_run_batch_trigger.md) | Run a batch trigger on a set of records |
| [transaction](save_trigger_transaction.md) | Wrap a set of triggers in a database transaction |

### Utilities

| Trigger | Description |
| --- | --- |
| [exception](save_trigger_exception.md) | Conditional exception raising / error bubble-up (critical for rolling back transactions) |
| [log](save_trigger_log.md) | Write a log entry (useful for debugging and audit trails) |

## Lifecycle Hooks

All save trigger types support `on_complete` and `on_failure` lifecycle hooks. These fire additional triggers after the main trigger succeeds or fails.

- **`on_complete`**: triggers to run after successful completion
- **`on_failure`**: triggers to run when an exception is raised (does NOT re-raise by default unless the `exception` save trigger with `original_failure: true` is executed)

Both accept a single trigger hash or an array of trigger configurations.

### Top-level usage

Place `on_complete` / `on_failure` alongside the trigger's own configuration keys:

```yaml
save_trigger:
  on_create:
    log:
      message: 'Processing record'
      severity: info
      on_complete:
        - log:
            message: 'Processing completed'
            severity: info
      on_failure:
        - log:
            message: 'Processing failed'
            severity: error
```

### Per-entry usage

For triggers that accept multiple named entries (e.g. `add_tracker`, `create_reference`, `update_this`), place `on_complete` / `on_failure` inside each entry:

```yaml
save_trigger:
  on_create:
    add_tracker:
      - Q1:
          with:
            sub_process_name: Review
            protocol_event_name: Done
          on_complete:
            - log:
                message: 'Tracker Q1 added'
                severity: info
      - Q2:
          with:
            sub_process_name: Review
            protocol_event_name: Pending
          on_failure:
            - log:
                message: 'Tracker Q2 failed'
                severity: error
```

### Transaction & Rollback Behavior

When an exception occurs during the execution of a save trigger in a database transaction (or standard model save transaction):

1. **Without an `on_failure` block**: If no `on_failure` hooks are defined, the exception propagates immediately, causing the database transaction to rollback, rolling back any actions like `add_tracker` already performed inside the transaction.
2. **With an `on_failure` block**: By default, `on_failure` intercepts and swallows the raised exception to run its child triggers. Since the exception is caught, the surrounding database transaction completes and **commits successfully**. Any triggers executed successfully within `on_failure` (e.g. `add_tracker` or status updates) will be committed to the database as normal. Handlers queued (such as `background` or `notify` jobs) are posted to delayed_job and executed.
3. **Re-raising an Exception**: If you want to perform cleanup or logging in `on_failure` but still rollback the database transaction, you must explicitly raise an exception at the end of the `on_failure` block. This is achieved using the `exception` save trigger:

   ```yaml
   on_failure:
     - log:
         message: 'Tracker addition failed, rolling back save'
         severity: error
     - exception:
         original_failure: true
   ```

   Executing `exception: { original_failure: true }` will re-raise the original exception, restoring transaction rollback behavior. Any side effects executed in external services (like third-party APIs or emails already sent out) cannot be rolled back by the database transaction.

## Event Keys

Only one of `on_create`, `on_disable` or `on_update` runs for a given save - they are mutually
exclusive and checked in that order. For example, a record that is created with `disabled` already
set to `true` fires `on_create`, not `on_disable`; an existing record whose `disabled` field
switches to `true` fires `on_disable`, not `on_update`. `before_save` and `on_upload` are evaluated
separately from that priority order (see below).

- **`on_create`**: runs once a new record has been saved and its database transaction has
  committed. Use it to react to record creation - sending notifications, creating references to
  other records, adding trackers, and so on.
- **`on_update`**: runs once an existing record's changes have been saved and committed. Same
  timing and use cases as `on_create`, but for updates rather than creation.
- **`on_save`**: a shorthand that cascades into both `on_create` and `on_update`. Tasks configured
  under `on_save` run first, followed by any tasks configured directly under `on_create` /
  `on_update` for that same event. Use `on_save` for logic that should apply regardless of whether
  the record was newly created or updated; use `on_create` / `on_update` directly when the logic
  needs to differ by action.
- **`on_disable`**: runs once a record whose definition includes a `disabled` field has had that
  field switched from `false` to `true` and the change has been committed. Use it for cleanup or
  notifications that should happen specifically when a record is disabled.
- **`on_upload`**: runs once a batch of file uploads to an NfsStore filestore container has
  completed. This event key only applies to filestore containers, not general dynamic models or
  activity logs. Use it to notify users or process newly uploaded files.
- **`before_save`**: runs before the record is persisted, as part of the same database transaction
  as the record's own save (rather than after, like the event keys above). Because of this:
  - Any exception raised by a `before_save` trigger aborts the save entirely - the record is
    **not** persisted at all.
  - By contrast, an exception raised by an `on_create` / `on_update` / `on_disable` / `on_upload`
    trigger runs *after* the record has already been committed, so it can never roll back the
    record's own persistence - only the effects of trigger tasks executed after the failure point
    (see "Transaction & Rollback Behavior" below).
  - `before_save` is typically used to derive or compute field values (e.g. with `update_this`)
    so the calculated result is included in the record's own insert/update, and is visible to
    `on_create` / `on_update` triggers that run afterwards.
  - **Caution**: configuring `update_this` under `before_save` to update the current record (the
    default target) causes a reentrant save of that same record from within its own `before_save`
    callback. This is safe from infinite recursion, but it can cause the record's `on_create`
    trigger to be silently skipped. If you need a value computed in `before_save` to be readable
    by an `on_create` / `on_update` trigger without this side effect, use `set_variables` instead
    and read it back via `{{variables.name}}`.
