# `creatable_if`

## Conditional Creation

Control whether a new record can be created, based on a [conditions](conditions.md) reference evaluated at runtime.

### Pattern 1: Always Creatable

```yaml
!defs(extra_options_creatable_if_pattern_1_always_defs.yaml)
```

### Pattern 2: Never Creatable

```yaml
!defs(extra_options_creatable_if_pattern_2_never_defs.yaml)
```

### Pattern 3: Conditional Creation

```yaml
!defs(extra_options_creatable_if_pattern_3_conditional_defs.yaml)
```

`creatable_if` must be a hash using the standard [conditions](conditions.md) syntax.
