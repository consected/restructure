# `create_reference`

## Create a Reference to Another Model

Create a model reference (and optionally a related record) when this trigger fires.

### Standalone Dynamic Models

Standalone dynamic models (those defined with no `foreign_key_name`, i.e. `no_master_association`)
are supported as targets. These models have no `master_id` column and are not associated with
a specific master record. When `create_reference` targets a standalone model, the record is
created directly using the model class rather than through the master association. See
[record scoping](scoping.md) for how this affects conditions and substitutions written
against such a model.

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

### Pattern 1: Create a reference from the current item (default)

The most common form - `in: this` creates the reference from the record that fired the trigger.

```yaml
!defs(save_triggers_create_reference_pattern_1_this_defs.yaml)
```

### Pattern 2: Create under the master, with a model reference

`in: master_with_reference` creates the record under the master and also creates a model
reference from the master. Use `in: master` instead to create the record under the master
WITHOUT a model reference.

```yaml
!defs(save_triggers_create_reference_pattern_2_master_defs.yaml)
```

### Pattern 3: Create a reference from a specific record

`in: specific_record` creates the reference from a record looked up by criteria, rather than
from the current item or the master.

```yaml
!defs(save_triggers_create_reference_pattern_3_specific_record_defs.yaml)
```

### Pattern 4: Reference an existing record

`to_existing_record` attaches a reference to an already-existing record instead of creating a
new one.

```yaml
!defs(save_triggers_create_reference_pattern_4_to_existing_record_defs.yaml)
```

### Pattern 5: Map attributes from a related item

`with_result` maps attributes from one or more related items into the newly created record.
`with:` fields (if also present) override any attributes set here.

```yaml
!defs(save_triggers_create_reference_pattern_5_with_result_defs.yaml)
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
