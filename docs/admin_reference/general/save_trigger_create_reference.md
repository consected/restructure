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

### Source Items Without Master Association

When the source item (the item firing the trigger) has no master association, set
`this_has_no_master_association: true` alongside `in: none`. This forces the target
record to be created directly using its model class, bypassing the master association
lookup that would otherwise fail.

```yaml
save_trigger:
  on_create:
    create_reference:
      - dynamic_model__target_recs:
          in: none
          force_create: true
          force_not_valid: true
          this_has_no_master_association: true
          with:
            master_id: -1
            value1: some value
```
