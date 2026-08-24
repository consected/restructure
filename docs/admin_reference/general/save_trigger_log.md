# `log`
## Log a Message

Write a log entry when this trigger fires. Useful for debugging and audit trails.

```yaml
!defs(save_triggers_log_options_defs.yaml)
```

### Pattern 1: Log a message with substitutions

`message` supports `{{...}}` substitutions. `severity` may be `debug`, `info` (default),
`warn` or `error`, and selects which `Rails.logger` method is used.

```yaml
!defs(save_triggers_log_pattern_1_basic_defs.yaml)
```

