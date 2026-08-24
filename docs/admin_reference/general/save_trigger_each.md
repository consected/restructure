# `each`
## Iterate Over a List and Apply Triggers

Iterate over a list of values (literal, substitution, or conditional) and apply a set of trigger tasks for each item. The iterator index and value are available inside the triggers via `{{save_trigger_results.iterator_index}}` and `{{save_trigger_results.iterator_value}}`.

```yaml
!defs(save_triggers_each_options_defs.yaml)
```

### Pattern 1: Iterate over a substitution-derived list

`value:` uses a triple-curly substitution with the `split_csv` formatter to derive a list from
a field, then `if:` skips blank/nil iterations.

```yaml
!defs(save_triggers_each_pattern_1_basic_defs.yaml)
```

