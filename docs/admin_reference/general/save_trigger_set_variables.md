# `set_variables`
## Set Variables for Subsequent Triggers

Define one or more named variables to be used by subsequent trigger substitutions via `{{variables.name}}`.

```yaml
!defs(save_triggers_set_variables_options_defs.yaml)
```

### Pattern 1: Set a simple literal or substituted value

```yaml
!defs(save_triggers_set_variables_pattern_1_simple_defs.yaml)
```

### Pattern 2: Set a Hash value using object:

```yaml
!defs(save_triggers_set_variables_pattern_2_object_defs.yaml)
```

### Pattern 3: Set a nested key using dot-notation

```yaml
!defs(save_triggers_set_variables_pattern_3_dot_notation_defs.yaml)
```