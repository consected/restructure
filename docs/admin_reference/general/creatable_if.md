# `creatable_if`

## Conditional Creation

Control whether a new record can be created, based on a [conditions](conditions.md) reference evaluated at runtime.

The condition is not evaluated against the record that would be created — that record does
not exist yet. It is evaluated against an existing record: the current activity log record
for an extra log type, or the record holding the configuration for a `references:` entry.
The records a condition can reach are those belonging to that record's master — see
[record scoping](scoping.md).

```yaml
!defs(extra_options_creatable_if_defs.yaml)
```

### Pattern 1: Always creatable

```yaml
!defs(extra_options_creatable_if_pattern_1_always_defs.yaml)
```

### Pattern 2: Never creatable

```yaml
!defs(extra_options_creatable_if_pattern_2_never_defs.yaml)
```

### Pattern 3: Creatable only when conditions are met

```yaml
!defs(extra_options_creatable_if_pattern_3_conditional_defs.yaml)
```

