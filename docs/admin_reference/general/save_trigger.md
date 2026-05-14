# `save_trigger`

## Save Trigger Actions

Define actions to perform automatically when a record is created, updated, saved, disabled, uploaded, or before saving. Each event key (`on_create`, `on_update`, `on_save`, `on_disable`, `on_upload`, `before_save`) takes an ordered list of trigger tasks.

```yaml
!defs(extra_options_save_trigger_defs.yaml)
```

## Trigger Types

Each trigger task listed under an event key corresponds to one of the following trigger types:

| Trigger | Description |
|---|---|
| [add_tracker](save_trigger_add_tracker.md) | Add a tracker entry |
| [create_master](save_trigger_create_master.md) | Create a new master record |
| [create_reference](save_trigger_create_reference.md) | Create a reference to another model |
| [change_user_roles](save_trigger_change_user_roles.md) | Add or remove user roles |
| [create_filestore_container](save_trigger_create_filestore_container.md) | Create an NFS filestore container |
| [generate_document](save_trigger_generate_document.md) | Generate a document from a template and store in a filestore container |
| [notify](save_trigger_notify.md) | Send a notification |
| [pull_emails](save_trigger_pull_emails.md) | Read MIME emails from S3, filesystem, or IMAP and run nested triggers per email |
| [pull_external_data](save_trigger_pull_external_data.md) | Pull data from an external source |
| [redcap_request](save_trigger_redcap_request.md) | Make a REDCap API request |
| [set_item_flags](save_trigger_set_item_flags.md) | Set item flags |
| [set_variables](save_trigger_set_variables.md) | Set variables for subsequent substitutions and triggers |
| [update_reference](save_trigger_update_reference.md) | Update a referenced record |
| [update_this](save_trigger_update_this.md) | Update fields on the current record |
| [full_text_search](save_trigger_full_text_search.md) | Build and persist PostgreSQL `tsvector` search indexes |
| [run_batch_trigger](save_trigger_run_batch_trigger.md) | Run a batch trigger |
| [log](save_trigger_log.md) | Log a message |
| [transaction](save_trigger_transaction.md) | Wrap triggers in a transaction |
| [background](save_trigger_background.md) | Run a trigger in the background |
| [reload_this](save_trigger_reload_this.md) | Reload the current record |
| [case](save_trigger_case.md) | Conditionally branch trigger execution |
| [set_save_trigger_results](save_trigger_set_save_trigger_results.md) | Set save trigger result values |

The list above matches the validated save trigger action names used by option config validation.

## Lifecycle Hooks

All save trigger types support `on_complete` and `on_failure` lifecycle hooks. These fire additional triggers after the main trigger succeeds or fails.

- **`on_complete`**: triggers to run after successful completion
- **`on_failure`**: triggers to run when an exception is raised (the original exception is re-raised afterwards)

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
