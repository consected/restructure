# `exception`

## Conditional Exception Raising

Raise an `FphsException` or from within on_failure lifecycle hooks re-raise the original failure. Extremely useful for conditional validation, custom error bubbles, and rolling back database transactions.

```yaml
!defs(save_triggers_exception_options_defs.yaml)
```
