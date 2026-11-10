# `each`
## Iterate Over a List and Apply Triggers

Iterate over a list of values (literal, substitution, or conditional) and apply a set of trigger tasks for each item. `each` is a composable trigger-list entry, so it can be used directly in save-trigger event lists, `on_complete`, `on_failure`, `case` branches, `transaction`, `background`, and other nested trigger lists. The iterator index and value are available inside nested triggers and their lifecycle callbacks via `{{save_trigger_results.iterator_index}}` and `{{save_trigger_results.iterator_value}}`.

```yaml
!defs(save_triggers_each_options_defs.yaml)
```

### Pattern 1: Iterate over a substitution-derived list

`value:` uses a triple-curly substitution with the `split_csv` formatter to derive a list from
a field, then `if:` skips blank/nil iterations.

```yaml
!defs(save_triggers_each_pattern_1_basic_defs.yaml)
```

### Pattern 2: Name nested iterator contexts

By default, each loop stores its context in `save_trigger_results.iterator_index` and
`save_trigger_results.iterator_value`. Nested loops intentionally overwrite those default
keys. Give loops different names when both contexts are needed:

```yaml
!defs(save_triggers_each_pattern_2_named_iterator_defs.yaml)
```

This produces four log entries: `0/outer_a => 0/inner_a`,
`0/outer_a => 1/inner_b`, `1/outer_b => 0/inner_a`, and
`1/outer_b => 1/inner_b`.

`value:` and `do:` may be omitted for compatibility with older configurations. Without
`value:`, the `do:` list runs once with a nil iterator value. Without `do:`, the iteration
produces no nested trigger results.

