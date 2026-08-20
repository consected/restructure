# Conditions: Search Scope

Table conditions are joined to the current record's master by default, so only records
belonging to that master are considered. These options change what is searched.

See the [conditions reference](conditions.md) for the overall syntax.

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
