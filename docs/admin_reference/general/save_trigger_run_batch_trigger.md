# `run_batch_trigger`
## Run a Batch Trigger

Schedule or immediately run a batch trigger for a defined set of records when this trigger fires.

```yaml
!defs(save_triggers_run_batch_trigger_options_defs.yaml)
```

### Pattern 1: Run synchronously (foreground)

`resource_name` must have a `batch_trigger:` defined in its own configuration (see
[batch_trigger](batch_trigger.md)). `limit` optionally caps the number of records processed.

```yaml
!defs(save_triggers_run_batch_trigger_pattern_1_foreground_defs.yaml)
```

### Pattern 2: Queue to run in the background

```yaml
!defs(save_triggers_run_batch_trigger_pattern_2_background_defs.yaml)
```

