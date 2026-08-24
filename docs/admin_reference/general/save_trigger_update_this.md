# `update_this`
## Update the Current Record

Update fields on the current record when this trigger fires. Commonly used in `before_save` to set computed values before the save completes.

```yaml
!defs(save_triggers_update_this_options_defs.yaml)
```

### Pattern 1: Update the current item's own attributes

`embedded_item:` (nested within `with:`) updates the item's embedded item at the same time.

```yaml
!defs(save_triggers_update_this_pattern_1_basic_defs.yaml)
```

### Pattern 2: Map attributes from a related item using with_result

```yaml
!defs(save_triggers_update_this_pattern_2_with_result_defs.yaml)
```

