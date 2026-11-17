# Conditions: Returning Values

As well as producing a true / false result, a condition can return data. This is what
allows save triggers, preset fields, field defaults and `set_variables` to look values up
from other records using the same syntax as any other condition.

A condition returns a value when one of the return keywords appears in place of a field's
expected value. Records are considered most recently created first, so a single value or
result is taken from the latest matching record.

See the [conditions reference](conditions.md) for the overall syntax.

## Returning a field value

```yaml
!defs(conditions_returns_1_return_value_defs.yaml)
```

```yaml
!defs(conditions_returns_2_return_value_list_defs.yaml)
```

## Returning records

```yaml
!defs(conditions_returns_3_return_result_defs.yaml)
```

## Returning a fixed value

```yaml
!defs(conditions_returns_4_return_constant_defs.yaml)
```

## Filtering and returning the same field

```yaml
!defs(conditions_returns_5_condition_return_flag_defs.yaml)
```

## Using a sub-query as a comparison value

```yaml
!defs(conditions_returns_6_lookup_defs.yaml)
```

## Summary

| Keyword | Returns |
| --- | --- |
| `return_value` | The field value from the latest matching record |
| `return_value_list` | An array of the field value from every matching record |
| `return_result` | The latest matching record itself |
| `return_all_results` | Every matching record |
| `return_constant` | A literal value, when the surrounding conditions match |

`return_result` and `return_all_results` ignore the field name they are given, so a name
such as `return:` may be used for readability.
