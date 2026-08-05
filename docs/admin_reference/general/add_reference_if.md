# `add_reference_if`

## Conditional Reference Addition

Control whether a reference can be added to this record, based on a [conditions](conditions.md) reference evaluated at runtime.

### Pattern 1: Always Allow Adding The Reference

```yaml
!defs(extra_options_add_reference_if_pattern_1_always_defs.yaml)
```

### Pattern 2: Never Allow Adding The Reference

```yaml
!defs(extra_options_add_reference_if_pattern_2_never_defs.yaml)
```

### Pattern 3: Conditional Reference Addition

```yaml
!defs(extra_options_add_reference_if_pattern_3_conditional_defs.yaml)
```

`add_reference_if` must be a hash using the standard [conditions](conditions.md) syntax.
