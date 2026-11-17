# `batch_trigger`
## Batch Trigger Actions

Define actions to perform for each record in a batch. Uses the same trigger task types as [save_trigger](save_trigger.md). To schedule batch processing, see [`_configurations`](configurations.md).

Validation rules:
- `batch_trigger` must be a hash.
- `on_record` is the trigger task list and must be either:
	- a single trigger hash, or
	- an array of trigger hashes.
- Trigger action names and trigger-specific keys are validated using the same per-type rules as `save_trigger`.

```yaml
!defs(extra_options_batch_trigger_defs.yaml)
```
