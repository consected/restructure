# `set_save_trigger_results`
## Set Save Trigger Result Values

Explicitly set values in the `save_trigger_results` store, making them available to subsequent trigger tasks within the same transaction via `{{save_trigger_results.<key>}}` substitutions.

```yaml
!defs(save_triggers_set_save_trigger_results_options_defs.yaml)
```

### Pattern 1: Set a simple literal or substituted value

```yaml
!defs(save_triggers_set_save_trigger_results_pattern_1_simple_defs.yaml)
```

### Pattern 2: Set a Hash value using object:

```yaml
!defs(save_triggers_set_save_trigger_results_pattern_2_object_defs.yaml)
```

### Pattern 3: Set a nested key using dot-notation

`element:` may use dot-notation to set a nested key within an existing Hash result, without
replacing the whole value.

```yaml
!defs(save_triggers_set_save_trigger_results_pattern_3_dot_notation_defs.yaml)
```

