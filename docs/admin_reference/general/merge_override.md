# `_merge_override`
## Deep-Merge Overrides into All Definitions

Keys are deep-merged into all dynamic definitions. These inner items take precedence over the later per-definition inner items, while the rest of each key definition remains untouched.

```yaml
!defs(extra_options_top_level_merge_override_defs.yaml)
```
