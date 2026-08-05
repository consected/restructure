# `show_if`

## Conditional Field Visibility

Control the visibility of individual fields based on the values of other fields or the current view mode. Supports `all`, `any`, `not_all`, `not_any` logic blocks, regex field matching, and embedded item conditions.

### Pattern 1: Simple Field-to-Field Condition

```yaml
!defs(extra_options_show_if_pattern_1_simple_defs.yaml)
```

### Pattern 2: Combined Conditions

```yaml
!defs(extra_options_show_if_pattern_2_combined_defs.yaml)
```

### Pattern 3: Embedded Item Condition

```yaml
!defs(extra_options_show_if_pattern_3_embedded_item_defs.yaml)
```

### Pattern 4: Nested Embedded Conditions

```yaml
!defs(extra_options_show_if_pattern_4_nested_embedded_defs.yaml)
```

### Pattern 5: Regex Key

```yaml
!defs(extra_options_show_if_pattern_5_regex_defs.yaml)
```

### Pattern 6: Submit Button Visibility

```yaml
!defs(extra_options_show_if_pattern_6_submit_button_defs.yaml)
```

Each top-level `show_if` entry must be a hash of conditions. Field keys may be literal field names, regex keys, or `submit_buttons_<button_id>`.
