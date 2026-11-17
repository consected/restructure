# Conditions: Record Sources

A record source is the key directly beneath a selection type. It names either a database
table (a resource name such as `player_contacts`, `dynamic_model__some_tables` or
`activity_log__some_type`) or one of the special sources described here.

Table sources are joined into a single database query. Special sources cannot be joined,
so they are evaluated in memory against a specific record. This also means they see
**unsaved** attribute values, which is what makes them usable during validation.

See the [conditions reference](conditions.md) for the overall syntax.

## The current record

```yaml
!defs(conditions_sources_1_this_defs.yaml)
```

A value from the current record can also be used as the value a table field is compared
against.

```yaml
!defs(conditions_sources_2_field_from_this_defs.yaml)
```

### Previous values

```yaml
!defs(conditions_sources_3_previous_value_defs.yaml)
```

## The record referring to this one

`referring_record` is set either from the context of the current request, or from the
single model reference pointing at the current record. `top_referring_record` follows the
chain of references to its outermost record.

```yaml
!defs(conditions_sources_4_referring_record_defs.yaml)
```

## Testing whether a related record exists

```yaml
!defs(conditions_sources_5_exists_defs.yaml)
```

## Records referenced by this record

`this_references` narrows a table condition to the records that the current record
actually references, rather than every record of that type belonging to the master.

```yaml
!defs(conditions_sources_6_this_references_defs.yaml)
```

```yaml
!defs(conditions_sources_7_parent_references_defs.yaml)
```

## Records selected by what they reference

```yaml
!defs(conditions_sources_8_ids_referencing_defs.yaml)
```

## The current user

```yaml
!defs(conditions_sources_9_current_user_defs.yaml)
```

To search the `users` table for a user other than the current one, see
[search scope](conditions_scope.md).

## Other special sources

```yaml
!defs(conditions_sources_10_other_sources_defs.yaml)
```

## Summary

| Source | Record it resolves to |
| --- | --- |
| `this` | The record being evaluated |
| `referring_record` | The record referring to this one |
| `top_referring_record` | The outermost record in a chain of references |
| `reference` | The current referenced record while iterating references |
| `embedded_item` | The record embedded in the current activity log entry |
| `parent` | The parent item, for records that have one, such as filestore containers |
| `user` | The current user |
| `this_references` | Records referenced by this record |
| `parent_references` | Records referenced by this record's referring record |
| `parent_or_this_references` | As `parent_references`, falling back to `this_references` |
| `ids_referencing` | Records that reference a separately selected target record |
