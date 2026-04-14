# `each`
## Iterate Over a List and Apply Triggers

Iterate over a list of values (literal, substitution, or conditional) and apply a set of trigger tasks for each item. The iterator index and value are available inside the triggers via `{{save_trigger_results.iterator_index}}` and `{{save_trigger_results.iterator_value}}`.

```yaml
!defs(save_triggers_each_options_defs.yaml)
```
