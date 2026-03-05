# Standard Options — Reusable YAML Anchors

Pre-defined YAML anchors for common option patterns (never creatable, never editable, never showable, blank/not-blank conditions, etc.). Reference these anchors with `<<: *anchor_name` in your configuration to avoid repetition.

```yaml
!defs(extra_options_standard_option_defs.yaml)
```
