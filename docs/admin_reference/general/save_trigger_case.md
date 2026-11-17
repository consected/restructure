# `case`
## Conditional Trigger Branching

Evaluate conditions and execute different sets of trigger tasks depending on which branch matches. Similar to a case/switch statement in programming.

Each branch is evaluated in order:
- **when:** a conditional expression (same format as `showable_if`, `editable_if`, etc.)
  evaluated against the current item.
- **then:** an array of save triggers to execute if the `when` condition is true.
- **else:** (optional, must be last) an array of save triggers to execute if no `when`
  condition matched.

Only the first matching branch executes. If no `when` condition matches and no `else` branch
is provided, no triggers run. This is useful when different actions should be taken based on
field values, avoiding the need for multiple identical `if:` conditions on individual triggers.

```yaml
!defs(save_triggers_case_options_defs.yaml)
```

### Pattern 1: Branch on field value, with a fallback else

```yaml
!defs(save_triggers_case_pattern_1_basic_defs.yaml)
```

