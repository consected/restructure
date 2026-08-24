# `field_options`
## Per-Field Configuration

Configure individual field behaviour: default and preset values, validation patterns, display formatters, field type overrides (`edit_as`), big-select dialogs, blank handling, and calculation options.

```yaml
!defs(extra_options_field_options_defs.yaml)
```

## Value, Preset, and Active Value Timing

`value`, `blank_value`, `preset_value`, `blank_preset_value` and `active_value` all accept a
literal, `now()`, `today()`, a `{{substitution}}`, a return_value Hash lookup (Pattern 7), or
an Array of strings for multi-value fields (Pattern 8) - but are applied at different times:

- `value` is set in the form fields UI only, before the item has been created and only if no
  `preset_value` has been set. It is not set before building the instance, so is not available
  to data conditions.
- `blank_value` is the same, but applies once the item has been created and the current value
  is blank.
- `preset_value` is set when building the instance, so is available to conditions (e.g.
  `embed_resource_name` logic) - but it is not applied to already-persisted instances.
- `blank_preset_value` is the same as `preset_value`, but only applies when the attribute is
  blank when building the instance.
- `active_value` (Pattern 9) is re-evaluated every time an instance is initialized or accessed,
  and the computed value IS persisted whenever the item is saved. This allows live UI
  substitutions using data that wouldn't otherwise be available. If the item isn't saved, the
  live value is lost and is re-evaluated on the next access.
- `selected` is normally computed automatically from `value`/`blank_value` at render time; it
  is not typically set directly in configuration.

### Pattern 7: value/preset_value via a return_value Hash lookup

```yaml
!defs(extra_options_field_options_pattern_7_value_lookup_defs.yaml)
```

### Pattern 8: value/preset_value as an Array of strings

For multi-value fields (e.g. multi-select).

```yaml
!defs(extra_options_field_options_pattern_8_value_array_defs.yaml)
```

### Pattern 9: active_value with a live substitution

```yaml
!defs(extra_options_field_options_pattern_9_active_value_defs.yaml)
```

## edit_as: Select Field Overrides

`edit_as` only applies to `select_`/`select_record_*` field types. Beyond `field_type` and
`alt_options` (Pattern 1 below), it accepts:
- `general_selection`: use a general selection definition with an alternative name, or
  belonging to a different prefix name
- `value_attr`/`label_attr`: attribute name(s) to use for the selection value/label in
  `select_record_*` fields (`label_attr` may be an Array - see Patterns 3-4)
- `sort_order`: "attribute direction" (attribute is `value` or `label`, direction is `asc` or
  `desc`), e.g. `"value desc"`. Defaults to `"label asc"`.
- `no_assoc`: whether to skip using an association for `select_record_*` data lookup.
  Defaults to `true` for `select_record_from_table_*` field types and `false` for
  `select_record_from_*` field types, unless explicitly overridden.
- `select_filtering_target`: the field to filter when this field changes - pairs with
  `big_select.filtered` on the target field (see Pattern 5).

`alt_options` given as an Array of strings is converted to a Hash automatically, downcasing
each string to generate its value.

### Pattern 1: Override field_type and alt_options

Provide an alternative field type and a fixed set of selectable options for a `select_` field.

```yaml
!defs(extra_options_field_options_pattern_1_edit_as_defs.yaml)
```

## big_select: Modal Selection Dialog

`big_select` presents a `select_record_*` field as a searchable modal dialog instead of a
plain dropdown.

### Pattern 2: big_select basic

`hide_key` hides the database id from the displayed list and enables `'>>>'`/`'\n'`
separator processing in `label_attr` (Pattern 3) - it defaults to `true`. Setting it to `false`
shows the database key alongside the full label with no separator processing.
`hide_popover` (default `false`) shows an overlay with the selected value text instead of the
info popover button - an alternative presentation to `hide_key`, not combined with it.

```yaml
!defs(extra_options_field_options_pattern_2_big_select_basic_defs.yaml)
```

### Pattern 3: big_select with a two-part display

Use `' >>> '` (or `'\n'`) within `label_attr` to split each option into a primary heading and
a secondary description line.

```yaml
!defs(extra_options_field_options_pattern_3_big_select_separator_defs.yaml)
```

### Pattern 4: big_select grouped by category

`group_split_char` splits the first `label_attr` entry out as a group heading.

```yaml
!defs(extra_options_field_options_pattern_4_big_select_grouped_defs.yaml)
```

### Pattern 5: big_select filtered by another field

`select_filtering_target` on one field feeds `big_select.filtered` (default `false`) on
another, via `blank_preset_value` substitution.

```yaml
!defs(extra_options_field_options_pattern_5_big_select_filtered_defs.yaml)
```

## creatable: Inline Record Creation

### Pattern 6: creatable - allow creating a new record inline

`enabled` (default `false`) renders the field as a typeahead text input instead of a select
dropdown; entering a value that doesn't already exist in the source model creates it
automatically on save. Requires the user to have `create` access on the source dynamic model -
without it, the user can only select from existing items.

```yaml
!defs(extra_options_field_options_pattern_6_creatable_defs.yaml)
```

## Other Notes

- `class`, `capitalize`, `default_value`, `placeholder`, `min`, `max`, `step` are pass-through
  HTML input hints, forwarded directly to the rendered form field as-is.
- Fields absent from the current model are tolerated without warning - library `_default`
  blocks may legitimately inject `field_options` entries for fields on other models.

