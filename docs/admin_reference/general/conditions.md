# Conditions Reference

Conditions express the rules that decide whether something may happen, or what value
something should take. The same syntax is used everywhere a decision is made against
record data, including:

- `creatable_if`, `editable_if`, `showable_if`, `add_reference_if` and `valid_if`
- `if:` clauses within save triggers, batch triggers and config triggers
- server-side calculations, preset field values and field defaults

A condition is evaluated against a **current record** — the record being created,
edited, shown or validated — and normally against the other records belonging to the
same **master** record.

## How a condition is evaluated

A condition is a hash of **selection types**. Each selection type contains one or more
**record sources**, and each record source contains **field conditions**.

```yaml
!defs(conditions_core_6_syntax_defs.yaml)
```

Every selection type in the configuration must be satisfied — they are combined with
AND. The result is `true` or `false`, unless the condition asks for a value to be
returned instead.

### Selection types

| Type | Meaning |
| --- | --- |
| `all` | Every field condition must be satisfied |
| `any` | At least one field condition must be satisfied |
| `not_any` | No field condition may be satisfied |
| `not_all` | The field conditions must not all be satisfied together |

```yaml
!defs(conditions_core_1_selection_types_defs.yaml)
```

> **Important:** `all` and `not_all` require the field conditions for a table to be
> satisfied by **the same record**, because they are combined into a single query using
> inner joins. `any` and `not_any` test each field **independently**, using left joins,
> so `any` succeeds if any one field matches on any one record. Where several fields
> must match the same record within an `any`, put them in a nested `all` block.

### Unconditional results

```yaml
!defs(conditions_core_2_always_never_defs.yaml)
```

### Field value forms

```yaml
!defs(conditions_core_3_value_forms_defs.yaml)
```

### Repeating a selection type

A selection type may only appear once as a hash key, so add a suffix to use it again.
Anything after the selection type name is ignored, which also allows each block to be
given a meaningful name. A selection type may also be given a list of blocks.

```yaml
!defs(conditions_core_4_repeats_and_arrays_defs.yaml)
```

### Nesting

```yaml
!defs(conditions_core_5_nested_defs.yaml)
```

## Detailed references

| Reference | Covers |
| --- | --- |
| [Record sources](conditions_record_sources.md) | `this`, `referring_record`, `top_referring_record`, `reference`, `embedded_item`, `parent`, `user`, and the reference traversal keys |
| [Operators and values](conditions_operators.md) | `condition:` operators, JSON `element:`, `calculate:`, dynamic values and `and_latest_matches` |
| [Returning values](conditions_returns.md) | `return_value`, `return_value_list`, `return_result`, `return_all_results`, `return_constant` and `lookup` |
| [Search scope](conditions_scope.md) | `masters:`, `no_masters:`, `users`, `definition_resources`, item flags and activity shortcuts |
| [Validation messages](conditions_validation.md) | `invalid_error_message`, `validate:` and `hide_error` |

## Limitations to be aware of

- `condition:` operator comparisons on database tables are **not supported** within `any`
  or `not_any` blocks and raise an error at runtime. Place them in an `all` or `not_all`
  block, or nest an `all` block inside the `any`.
- A record source that cannot be resolved — for example `referring_record` when there is
  no referring record — raises an error rather than returning false. Use `exists` to test
  for presence first.
- Table conditions are joined to the current master by default. Use
  [`masters:` or `no_masters:`](conditions_scope.md) to search more widely.
- When `no_masters: {}` is used, the **first** table listed becomes the base of the
  query, so ordering matters.

## Examples in this reference

The runnable examples on these pages are checked automatically against a small set of
sample records, so that the documentation cannot drift away from the behaviour of the
platform. The sample data is a single master record with:

- an activity log entry (`activity_log__player_contact_phones`) with
  `extra_log_type: primary` and `select_who: user`
- an address with `city: portland`, `state: OR`, `zip: 12345` and `rank: 10`
- a player contact with `rec_type: email` and `data: sample@example.com`
- a current user holding the role `test`
