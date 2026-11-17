# `caption_before`

## Field Captions

Display text captions before specific fields, before submit button, or before all fields. Supports markdown formatting and [substitutions](../substitutions.md).

```yaml
!defs(extra_options_caption_before_defs.yaml)
```

### Pattern 1: Simple caption string

Specify a caption to appear before a field, hiding the field's label.

```yaml
!defs(extra_options_caption_before_pattern_1_simple_defs.yaml)
```

### Pattern 2: Caption hash with keep_label

Specify a field with a caption hash allowing an option to retain the label.

```yaml
!defs(extra_options_caption_before_pattern_2_keep_label_defs.yaml)
```

### Pattern 3: View-specific captions

Specify a field with captions that appear in different views.

```yaml
!defs(extra_options_caption_before_pattern_3_view_specific_defs.yaml)
```

