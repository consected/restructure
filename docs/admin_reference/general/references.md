# `references`

## Model References

Define relationships to other models that can be viewed, created, and managed within this definition's UI panel. Supports filtering, ordering, add modes, type selectors, display control, and disable/enable logic.

### Pattern 1: Simple Reference Definition

```yaml
!defs(extra_options_references_pattern_1_simple_defs.yaml)
```

### Pattern 2: `add_with` And `filter_by`

```yaml
!defs(extra_options_references_pattern_2_add_with_filter_defs.yaml)
```

### Pattern 3: `order_by` And `type_config`

```yaml
!defs(extra_options_references_pattern_3_order_type_config_defs.yaml)
```

### Pattern 4: Display Behavior

```yaml
!defs(extra_options_references_pattern_4_display_defs.yaml)
```

### Pattern 5: Disable And Reload Behavior

```yaml
!defs(extra_options_references_pattern_5_disable_behavior_defs.yaml)
```

Each reference entry must be a hash. Top-level keys are the referenced model names, whether declared directly or inside an array.
