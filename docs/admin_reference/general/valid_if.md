# `valid_if`

## Server-Side Validation Conditions

Define server-side conditions that must be satisfied for a record to be considered valid. If the conditions are not met, the save will be rejected with an appropriate error.

### Pattern 1: Trigger Map

```yaml
!defs(valid_if_pattern_1_trigger_map_defs.yaml)
```

### Pattern 2: Simple Current-Item Validation

```yaml
!defs(valid_if_pattern_2_simple_this_defs.yaml)
```

### Pattern 3: Multiple Current-Item Requirements

```yaml
!defs(valid_if_pattern_3_multiple_fields_defs.yaml)
```

### Pattern 4: Cross-Table Validation

```yaml
!defs(valid_if_pattern_4_cross_table_defs.yaml)
```

### Pattern 5: Mixed Validation Blocks

```yaml
!defs(valid_if_pattern_5_mixed_blocks_defs.yaml)
```

Top-level keys are limited to `on_save`, `on_create`, and `on_update`. Each trigger payload must be a hash using the standard [conditions](conditions.md) syntax.
