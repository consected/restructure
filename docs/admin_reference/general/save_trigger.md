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
| [notify](save_trigger_notify.md) | Send a notification |
| [pull_external_data](save_trigger_pull_external_data.md) | Pull data from an external source |
| [redcap_request](save_trigger_redcap_request.md) | Make a REDCap API request |
| [set_item_flags](save_trigger_set_item_flags.md) | Set item flags |
| [update_reference](save_trigger_update_reference.md) | Update a referenced record |
| [update_this](save_trigger_update_this.md) | Update fields on the current record |
| [run_batch_trigger](save_trigger_run_batch_trigger.md) | Run a batch trigger |
| [log](save_trigger_log.md) | Log a message |
| [transaction](save_trigger_transaction.md) | Wrap triggers in a transaction |
| [background](save_trigger_background.md) | Run a trigger in the background |
| [reload_this](save_trigger_reload_this.md) | Reload the current record |
| [case](save_trigger_case.md) | Conditionally branch trigger execution |
| [each](save_trigger_each.md) | Iterate over a list and apply triggers |
| [set_save_trigger_results](save_trigger_set_save_trigger_results.md) | Set save trigger result values |
| [with_attribute_values](save_trigger_with_attribute_values.md) | Map attribute values in trigger context |
