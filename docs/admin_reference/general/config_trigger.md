# `config_trigger`
## Configuration-Time Trigger

Define actions to perform when a dynamic definition is saved or updated in the admin panel. Runs `on_define` to add or update default configurations.

Validation rules:
- `config_trigger` must be a hash.
- `on_define` is normalized to an array and must resolve to:
	- a single trigger hash, or
	- an array of trigger hashes.
- Trigger action names and trigger-specific keys are validated using the same per-type rules as `save_trigger`.

```yaml
!defs(extra_options_config_trigger_defs.yaml)
```
