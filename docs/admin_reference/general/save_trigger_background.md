# `background`
## Run a Trigger in the Background

Defer a trigger task to run asynchronously in the background, outside the current request/response cycle.

All listed save triggers are queued to run together in a single background job. The save
operation returns immediately without waiting for the triggers to complete - useful for
long-running operations like sending notifications, processing large datasets, or calling
external APIs that shouldn't block the main request. The `current_user` context is preserved
in the background job. Lifecycle hooks on the outer `background` trigger still run in the
foreground after queuing; hooks on triggers inside `do:` run in the job.

The job loads the record again from the database by ID, so background triggers see the
saved record. Foreground `save_trigger_results` and `trigger_variables` are not copied
wholesale. To pass specific values, use the context form and select each value explicitly:

```yaml
background:
  with:
    loop_index: "{{save_trigger_results.loop_result_index}}"
    loop_value: "{{{save_trigger_results.loop_result_value}}}"
  do:
    - log:
        message: "Processing {{background_context.loop_index}} => {{background_context.loop_value}}"
```

Each `with` value is resolved in the foreground using the normal value-expression rules.
The selected values are available in the job as `background_context`; nested values can be
read with paths such as `{{background_context.payload.status}}`. Double braces convert a
value to text, while triple braces pass its original type. Missing double-curly values raise
unless `::ignore_missing` is used; missing triple-curly values become nil.

When `background` is inside `each`, one job is queued per iteration. Select that iteration's
value or index through `save_trigger_results` in `with` to give each job its own context.
Existing list and single-trigger background forms remain supported.

Context is serialized using ActiveJob's supported argument types and is limited to
`Settings::SaveTriggerBackgroundContextMaxBytes` (default 64 KB; override with
`FPHS_SAVE_TRIGGER_BG_CONTEXT_MAX_BYTES`). Unsupported objects, relations, and hashes with
unsupported keys raise an error when queuing; values are not coerced. Only keys explicitly
listed in `with` are serialized.

ActiveRecord records passed in context use GlobalID and are re-read when the job runs, so
unsaved in-memory changes are not included. A record deleted before execution, or a class no
longer available, causes ActiveJob deserialization to fail before `perform`; background
`on_failure` hooks do not run in that case. GlobalID resolves by payload class name and does
not use the dynamic resource allow-list. When a job has a `user_id`, the job user is assigned
as `current_user` to context records nested inside hashes and arrays; without a `user_id`,
context records are left unchanged.

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

### Pattern 2: Pass selected foreground context

```yaml
!defs(save_triggers_background_pattern_2_with_context_defs.yaml)
```
