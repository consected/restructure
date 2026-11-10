# `editable_if`

## Conditional Edit Access

Control whether an existing record can be edited, based on a [conditions](conditions.md) reference evaluated at runtime.

If not defined, the default is to allow editing only for the most recently created item in the list. Use `always: true` to make items always editable.

```yaml
!defs(extra_options_editable_if_defs.yaml)
```

### Pattern 1: Explicitly always editable

```yaml
!defs(extra_options_editable_if_pattern_1_always_defs.yaml)
```

### Pattern 2: Explicitly never editable

```yaml
!defs(extra_options_editable_if_pattern_2_never_defs.yaml)
```

### Pattern 3: Conditional editable rules using the standard conditions reference

```yaml
!defs(extra_options_editable_if_pattern_3_conditional_defs.yaml)
```

### Pattern 4: Merge reusable conditions with local rules

```yaml
!defs(extra_options_editable_if_pattern_4_merge_anchor_defs.yaml)
```

