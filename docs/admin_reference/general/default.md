# `_default` and `_default_additions` — Shared Defaults Across All Definitions

`_default` provides key-value pairs applied to every dynamic definition within the configuration. The actual per-definition values take precedence by replacing the full key.

`_default_additions` overrides or adds to `_default` values before any `_merge_*` or `_override` options are applied — primarily used by automated generation such as REDCap.

```yaml
!defs(extra_options_top_level_default_defs.yaml)
```
