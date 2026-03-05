# Activity Log: Detailed Options

## Config Library Include

- [@library](../general/library.md) — include reusable Config Library content

## Top-Level Structural Options

These options appear outside any `default:` or extra log type key.

- [_constants](../general/constants.md) — runtime constant substitutions
- [_comments](../general/comments.md) — database table and field comments
- [_db_columns](../general/db_columns.md) — column type and index overrides
- [_configurations](../general/configurations.md) — runtime, batch trigger scheduling, versioning, and other structural settings
- [_data_dictionary](../general/data_dictionary.md) — data dictionary integration
- [_definitions](../general/definitions.md) — reusable YAML anchors
- [_default](../general/default.md) — shared defaults applied to all extra log types (`_default_additions` also covered)
- [_merge_default](../general/merge_default.md) — deep-merge defaults into all extra log types
- [_merge_override](../general/merge_override.md) — deep-merge overrides into all extra log types
- [_override](../general/override.md) — override keys across all extra log types

## Extra Log Type Definition Structure

- [Extra Log Type](../general/extra_log_type.md) — defining named extra log type keys

## Common Options (within `default:` and each extra log type)

- [label / button_label](../general/label.md) — display and add-button labels
- [fields](../general/fields.md) — ordered list of displayed fields
- [caption_before](../general/caption_before.md) — text captions before fields or submit
- [labels](../general/labels.md) — field label overrides
- [show_if](../general/show_if.md) — conditional field visibility
- [view_options](../general/view_options.md) — layout, ordering, embedding, and UI class settings
- [filestore](../general/filestore_container.md) — attach a filestore container
- [save_action](../general/save_action.md) — post-save UI actions
- [field_options](../general/field_options.md) — per-field configuration (values, validators, edit_as, big-select)
- [preset_fields](../general/preset_fields.md) — preset multiple fields from related items on initialisation
- [dialog_before](../general/dialog_before.md) — confirmation dialogs before submit

## Conditional Access Options

- [creatable_if](../general/creatable_if.md) — conditional creation
- [editable_if](../general/editable_if.md) — conditional edit access
- [showable_if](../general/showable_if.md) — conditional record visibility
- [add_reference_if](../general/add_reference_if.md) — conditional reference addition
- [valid_if](../general/valid_if.md) — server-side validation conditions

## Embedding and References

- [embed](../general/embed.md) — directly embed a single related item
- [references](../general/references.md) — define linked model references

## Triggers

- [save_trigger](../general/save_trigger.md) — actions on create, update, save, disable, upload, or before save
- [batch_trigger](../general/batch_trigger.md) — actions on each record in a batch
- [config_trigger](../general/config_trigger.md) — actions when the definition is saved in admin

## Filestore Options

These options are used in activity logs that manage NFS filestore containers. Typically stored in the Config Library for reuse.

- [filestore references](../general/filestore_references.md) — standard container reference configuration
- [filestore save_trigger](../general/filestore_save_trigger.md) — standard container creation trigger
- [nfs_store](../general/filestore_nfs_store.md) — upload pipeline, user file actions, and access control

## Activity Log Specific Options

- [e_sign](../general/e_sign.md) — electronic document signing configuration

## Conditions Reference

- [Conditions](../general/conditions.md) — full reference for condition syntax used in `*_if` options and trigger `if:` clauses

## Standard Options (Reusable Anchors)

- [Standard Options](../general/standard_options.md) — common YAML anchors for never-creatable, never-editable, blank conditions, etc.
- [Activity Log Standard Options](../general/activity_log_standard_options.md) — activity-log-specific anchors (e.g. not_completed_this_activity)
