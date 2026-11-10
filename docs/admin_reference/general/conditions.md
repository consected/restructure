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
| [Record scoping](scoping.md) | How a definition reaches its master record, and what changes when it has none |

## Limitations to be aware of

- `condition:` operator comparisons on database tables are **not supported** within `any`
  or `not_any` blocks and raise an error at runtime. Place them in an `all` or `not_all`
  block, or nest an `all` block inside the `any`.
- A record source that cannot be resolved — for example `referring_record` when there is
  no referring record — raises an error rather than returning false. Use `exists` to test
  for presence first.
- Table conditions are joined to the current master by default. Use
  [`masters:` or `no_masters:`](conditions_scope.md) to search more widely.
- A definition with no *Foreign key name* has no master record at all, so a table
  condition raises an error rather than returning false unless `masters:` or
  `no_masters:` is used. See [record scoping](scoping.md).
- When `no_masters: {}` is used, the **first** table listed becomes the base of the
  query, so ordering matters.

## Configuration warnings

When a dynamic definition, activity log, external identifier or page layout is saved, its
conditions are checked for problems that would otherwise only appear when a user triggers
the condition. These are shown as **condition configuration** notices alongside the other
configuration errors on the definition's details, and on the app type's components page.
Notices never prevent a save.

Conditions are checked wherever they are evaluated, including:

- `creatable_if`, `editable_if`, `showable_if`, `add_reference_if` and `valid_if`
- `references`: the `*_if` keys and the `add_with` values
- `save_action` and `set_variables`: the `if:` clauses, and the `set_variables` values
- `nfs_store` `can` conditions (activity logs)
- save, batch and config trigger tasks: `if:`, `success_if:`, `when:` (within `case`), `first:`,
  and `with:` and `value:` values, including tasks nested in `each`, `case`, `transaction` and `background`
- page layout `conditional_calculation` perspectives, which are evaluated with `no_masters: {}` added

Each **condition configuration** notice states the problem, followed by a snippet of the configuration
from its top-level key down to the offending key, holding the offending value. For example, a problem
in `showable_if` of the `default` option type shows:

```yaml
default:
  showable_if:
    all:
      missing_table:
        missing_field: unexpected
```

A list item, such as a page layout perspective, is shown as a one-item list. A condition that is inherited
from `_default` is shown within the option type it applies to.

### What is checked

- **Selection types**: top-level keys must be `all`, `any`, `not_all` or `not_any` (optionally with a suffix),
  `always`, `never`, `has_created_activity` or `has_not_created_activity`. A record source must not appear
  at the top level of a condition, and nested blocks are checked in the same way.
- **Record sources**: tables must be resources, associations of masters (including `*_item_flags`),
  or `masters`, `users` and `definition_resources`. The base table of `no_masters: {}` must be a known resource.
- **Field names** of `this`, `user` and tables, where the model is known.
- **Operators**: `condition:` operators must be valid for the record source. Database operators are not
  valid on `this`, and in-memory operators are not valid on database tables. Binary and array operators
  need a `value:`.
- **Return flags**: at most one of `return_value`, `return_value_list`, `return_result` or `return_all_results`,
  and only alongside a `condition:`. A value that is a near miss of a return keyword, such as `return_val`, is reported
  as a probable typo. Other strings, such as `return_call`, are literal values.
- **Database conditions within `any` and `not_any`**: these are not supported directly within the block.
  Move them into an `all` or `not_all` block, or nest an `all` block within the `any`.
- **Functions and validators**: `calculate:` functions and their `attributes:`, and `validate:` validator names.
- **Lookups and references**: `lookup:` must return `return_value` or `return_value_list`. `ids_referencing:`
  needs `target:` and a `from:` block that returns `return_all_results`. The forms of `this_references`,
  `parent_references` and `parent_or_this_references` are checked.
- **Typos**: keys that are not recognized alongside a `condition:`, such as `valu:`.

### What is not checked

- Problems that depend on data at runtime, such as no referring record or no current user.
- Field names on record sources whose model is only known at runtime: `referring_record`,
  `top_referring_record`, `parent`, `embedded_item`, `reference` and `definition_resources`.
- Table names are checked against the resources and associations that are currently loaded. A table
  from another definition that has not yet been generated is reported until it is available.
- Conditions in other settings, such as `show_if` and `preset_fields`.

If the checks themselves fail, a single **condition linter failed** warning is shown instead.

## Examples in this reference

The runnable examples on these pages are checked automatically against a small set of
sample records, so that the documentation cannot drift away from the behaviour of the
platform. The sample data is a single master record with:

- an activity log entry (`activity_log__player_contact_phones`) with
  `extra_log_type: primary` and `select_who: user`
- an address with `city: portland`, `state: OR`, `zip: 12345` and `rank: 10`
- a player contact with `rec_type: email` and `data: sample@example.com`
- a current user holding the role `test`
