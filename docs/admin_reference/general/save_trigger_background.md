# `background`
## Run a Trigger in the Background

Defer a trigger task to run asynchronously in the background, outside the current request/response cycle.

All listed save triggers are queued to run together in a single background job. The save
operation returns immediately without waiting for the triggers to complete - useful for
long-running operations like sending notifications, processing large datasets, or calling
external APIs that shouldn't block the main request. The `current_user` context is preserved
in the background job.

Results from the queue operation are stored in `save_trigger_results['background']`:
```
{
  status: 'queued',
  item_class: 'DynamicModel::ClassName',
  item_id: 123,
  trigger_count: 3,
  queued_at: <timestamp>
}
```

```yaml
!defs(save_triggers_background_options_defs.yaml)
```

### Pattern 1: Queue several triggers to run together

```yaml
!defs(save_triggers_background_pattern_1_basic_defs.yaml)
```

