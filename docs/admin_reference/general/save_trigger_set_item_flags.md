# `set_item_flags`
## Set Item Flags

Set or update item flags on the current or related record when this trigger fires.

```yaml
!defs(save_triggers_set_item_flags_options_defs.yaml)
```

### Pattern 1: Set the full flag list

`flags:` replaces the whole set of flags on the referenced item.

```yaml
!defs(save_triggers_set_item_flags_pattern_1_replace_defs.yaml)
```

### Pattern 2: Add and remove specific flags

`add_flags:`/`remove_flags:` adjust the existing flag set instead of replacing it.

```yaml
!defs(save_triggers_set_item_flags_pattern_2_add_remove_defs.yaml)
```

