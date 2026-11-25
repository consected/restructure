# `batch_trigger`
## Batch Trigger Actions

Define actions to perform for each record in a batch. Uses the same trigger task types as [save_trigger](save_trigger.md). To schedule batch processing, see [`_configurations`](configurations.md).

The schedule's `frequency` can use week-based durations such as `1 week` or `2 weeks`; pair it with a `run_at` value such as `monday 8:00am` to run at a specific weekday and time. An unrecognised `frequency` (anything other than `once` or a positive `n units`), a `run_at` without a `frequency`, or a `run_at` that is not a valid time (a single full date and time for `once`), is reported as a configuration error in the admin UI and the batch is not scheduled.

Validation rules:
- `batch_trigger` must be a hash.
- `on_record` is the trigger task list and must be either:
	- a single trigger hash, or
	- an array of trigger hashes.
- Trigger action names and trigger-specific keys are validated using the same per-type rules as `save_trigger`.

```yaml
!defs(extra_options_batch_trigger_defs.yaml)
```
