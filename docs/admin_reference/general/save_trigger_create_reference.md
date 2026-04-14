# `create_reference`

## Create a Reference to Another Model

Create a model reference (and optionally a related record) when this trigger fires.

### Standalone Dynamic Models

Standalone dynamic models (those defined with no `foreign_key_name`, i.e. `no_master_association`)
are supported as targets. These models have no `master_id` column and are not associated with
a specific master record. When `create_reference` targets a standalone model, the record is
created directly using the model class rather than through the master association.

All `in:` options are supported with standalone models. Since the target record has no
master association, the record is always created directly. The `in:` option only determines
whether and how a model reference is created:

- `this` — creates a model reference from the current item to the new record
- `referring_record` — creates a model reference from the referring record
- `master_with_reference` — creates a model reference from the master record
- `none` — creates the record only, no model reference (equivalent to `master` for standalone models)
- `specific_record` — creates a model reference from a looked-up record

The `none` option is particularly useful for standalone models where there is no master
association involved and no model reference is needed.

```yaml
!defs(save_triggers_create_reference_options_defs.yaml)
```
