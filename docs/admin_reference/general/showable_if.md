# `showable_if`

## Conditional Record Visibility

Control whether a record is shown in the list, based on a [conditions](conditions.md) reference evaluated at runtime.

### Pattern 1: Always Show

```yaml
!defs(extra_options_showable_if_pattern_1_always_defs.yaml)
```

### Pattern 2: Never Show

```yaml
!defs(extra_options_showable_if_pattern_2_never_defs.yaml)
```

### Pattern 3: Conditional Visibility

```yaml
!defs(extra_options_showable_if_pattern_3_conditional_defs.yaml)
```

`showable_if` must be a hash using the standard [conditions](conditions.md) syntax.
