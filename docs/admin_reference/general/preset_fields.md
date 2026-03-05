# `preset_fields`
## Preset Field Values from Related Items

Populate a set of fields on new item initialisation (or before creating a reference) by mapping attributes from a related item such as an embedded item or dynamic model record.

> Note: `field_options.<field_name>.preset_value` and `field_options.<field_name>.blank_preset_value` are evaluated *after* this and may override values set here.

Also see: [with_attribute_values](save_trigger_with_attribute_values.md) for attribute value mapping used within save triggers.

```yaml
!defs(extra_options_preset_fields_defs.yaml)
```
