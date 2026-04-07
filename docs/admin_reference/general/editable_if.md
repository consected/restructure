# `editable_if`

## Conditional Edit Access

Control whether an existing record can be edited, based on a [conditions](conditions.md) reference evaluated at runtime.

If not defined, the default is to allow editing only for the most recently created item in the list. Use `always: true` to make items always editable.

### Pattern 1: Always Editable

```yaml
!defs(extra_options_editable_if_pattern_1_always_defs.yaml)
```

### Pattern 2: Never Editable

```yaml
!defs(extra_options_editable_if_pattern_2_never_defs.yaml)
```

### Pattern 3: Conditional Edit Access

```yaml
!defs(extra_options_editable_if_pattern_3_conditional_defs.yaml)
```

### Pattern 4: Merge Shared Conditions With Local Rules

```yaml
!defs(extra_options_editable_if_pattern_4_merge_anchor_defs.yaml)
```

`editable_if` must be a hash using the standard [conditions](conditions.md) syntax.
