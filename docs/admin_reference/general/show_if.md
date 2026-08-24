# `show_if`

## Conditional Field Visibility

Control the visibility of individual fields based on the values of other fields or the current view mode. Supports `all`, `any`, `not_all`, `not_any` logic blocks, regex field matching, and embedded item conditions.

```yaml
!defs(extra_options_show_if_defs.yaml)
```

### Pattern 1: Simple field-to-field condition

```yaml
!defs(extra_options_show_if_pattern_1_simple_defs.yaml)
```

### Pattern 2: Combined conditions for one field

Use `all`, `any`, `not_all` or `not_any` when the field depends on more than one rule.

```yaml
!defs(extra_options_show_if_pattern_2_combined_defs.yaml)
```

### Pattern 3: Conditions that refer to an embedded item

`embedded_item` is available when the current option type defines an `embed:` configuration or otherwise exposes embedded-item substitutions.

```yaml
!defs(extra_options_show_if_pattern_3_embedded_item_defs.yaml)
```

### Pattern 4: Nested conditional groups with embedded_item

```yaml
!defs(extra_options_show_if_pattern_4_nested_embedded_defs.yaml)
```

### Pattern 5: Apply the same condition to multiple fields using a regex key

Example regex keys: `/^.+_complete/`, `field_[0-9]`, `/^status_.*$/`.

```yaml
!defs(extra_options_show_if_pattern_5_regex_defs.yaml)
```

### Pattern 6: Control submit buttons instead of data fields

```yaml
!defs(extra_options_show_if_pattern_6_submit_button_defs.yaml)
```

