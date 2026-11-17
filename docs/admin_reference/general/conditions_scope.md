# Conditions: Search Scope

Table conditions are joined to the current record's master by default, so only records
belonging to that master are considered. These options change what is searched.

See the [conditions reference](conditions.md) for the overall syntax, and
[record scoping](scoping.md) for how a definition comes to have a master record in the
first place — and what these options are needed for when it has none.

## Searching all master records

```yaml
!defs(conditions_scope_1_masters_defs.yaml)
```

## Searching without a master join

```yaml
!defs(conditions_scope_2_no_masters_defs.yaml)
```

## Searching the users table

```yaml
!defs(conditions_scope_3_users_defs.yaml)
```

Note the difference between `users` and `user`: `users` is the users table, searched like
any other table, while [`user`](conditions_record_sources.md) is the current user.

## The current definition's own records

```yaml
!defs(conditions_scope_4_definition_resources_defs.yaml)
```

## Item flags

```yaml
!defs(conditions_scope_5_item_flags_defs.yaml)
```

## Protocols, sub processes and protocol events

`tracker_history` conditions can name a protocol, sub process or protocol event, instead of looking up its id.
Use `protocol_name`, `sub_process_name` and `protocol_event_name` in place of `protocol_id`, `sub_process_id`
and `protocol_event_id`:

```yaml
not_all:
  tracker_history:
    notes: '{{select_reason}} ({{id}})'
    protocol_name: Study
    sub_process_name: Information
    protocol_event_name: Error
```

- Each name is looked up within its parent. The protocol is found first, then the sub process within that protocol,
  then the protocol event within that sub process. This means the same sub process and event names can be used under
  different protocols.
- A `sub_process_name` needs a `protocol_id` or `protocol_name` at the same level. A `protocol_event_name` needs a
  `sub_process_id` or `sub_process_name`. A parent can be given by id, for example `protocol_id: 27` with
  `sub_process_name: Information`.
- Give either the `_id` or the `_name` key for each level, not both.
- Values can be [substitutions](substitutions.md), such as `protocol_name: '{{select_reason}}'`.
- Names match active (not disabled) records exactly. A name that matches no record, or more than one record within
  its parent, or is blank, raises an error. It is never ignored, so a mistyped name cannot silently change the result
  of a `not_all` condition.

## Activity completion shortcuts

```yaml
!defs(conditions_scope_6_shortcuts_defs.yaml)
```

## Save trigger results

```yaml
!defs(conditions_scope_7_save_trigger_results_defs.yaml)
```

## Save trigger variables

```yaml
!defs(conditions_scope_8_trigger_variables_defs.yaml)
```

> The attribute is `trigger_variables`, even though the same values are written as
> `{{variables.<name>}}` in substitutions. A condition naming `variables` instead does not
> raise an error — the attribute is simply not found and the comparison is made against
> `nil`, which silently matches any test that allows a blank value.
