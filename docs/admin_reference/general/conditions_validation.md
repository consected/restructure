# Conditions: Validation Messages

When conditions are used to validate a record — through [`valid_if`](valid_if.md) — a
failure has to be explained to the user. The evaluator records which record source, field
and comparison failed, and turns that into a message against the field.

These keys let you control the wording. They have no effect when conditions are used for
anything other than validation.

See the [conditions reference](conditions.md) for the overall syntax.

## Custom messages

```yaml
!defs(conditions_validation_1_invalid_error_message_defs.yaml)
```

## Field validators

```yaml
!defs(conditions_validation_2_validate_defs.yaml)
```

## Suppressing a message

```yaml
!defs(conditions_validation_3_hide_error_defs.yaml)
```
