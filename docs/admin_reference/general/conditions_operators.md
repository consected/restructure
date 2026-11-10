# Conditions: Operators and Values

By default a field condition tests for equality, or for membership when given a list. A
hash value with a `condition` key performs some other comparison instead.

See the [conditions reference](conditions.md) for the overall syntax.

## Comparison operators

```yaml
!defs(conditions_operators_1_comparison_defs.yaml)
```

## Null tests and negation

```yaml
!defs(conditions_operators_2_null_and_not_defs.yaml)
```

## Length comparisons

```yaml
!defs(conditions_operators_3_length_defs.yaml)
```

## Full operator list

Not every operator is available everywhere. Conditions on database tables are turned into
SQL, while conditions on the in-memory record sources (`this`, `referring_record`, `user`
and the others listed in [record sources](conditions_record_sources.md)) are evaluated in
Ruby and support a slightly different set.

```yaml
!defs(conditions_operators_4_reference_defs.yaml)
```

> `condition:` comparisons on database tables cannot be used inside `any` or `not_any`
> blocks — they raise an error. Nest an `all` block inside the `any` instead.

## Elements within JSON fields

```yaml
!defs(conditions_operators_5_json_element_defs.yaml)
```

## Calculations

```yaml
!defs(conditions_operators_6_calculate_defs.yaml)
```

## Dynamic comparison values

```yaml
!defs(conditions_operators_7_dynamic_values_defs.yaml)
```

## Requiring the latest matching record to match

```yaml
!defs(conditions_operators_8_and_latest_matches_defs.yaml)
```
