# `update_reference`
## Update a Referenced Record

Update attributes on a referenced record when this trigger fires.

```yaml
!defs(save_triggers_update_reference_options_defs.yaml)
```

### Pattern 1: Update the latest matching reference

The simplest form of `first:` - updates the most recently created matching reference.

```yaml
!defs(save_triggers_update_reference_pattern_1_latest_defs.yaml)
```

### Pattern 2: Match by a value from the referring (parent) record

```yaml
!defs(save_triggers_update_reference_pattern_2_referring_record_defs.yaml)
```

### Pattern 3: Match via a parent's associated dynamic model id

```yaml
!defs(save_triggers_update_reference_pattern_3_parent_references_defs.yaml)
```

### Pattern 4: Map attributes from a related item using with_result

`with:` fields (if also present) take precedence over `with_result:` fields for the same attribute.

```yaml
!defs(save_triggers_update_reference_pattern_4_with_result_defs.yaml)
```

### force_not_editable_save / force_not_valid

`force_not_editable_save: true` allows the update to succeed even if the referenced item is
marked `not_editable`. `force_not_valid: true` allows the update to succeed even if `valid_if`
checks would otherwise fail.

