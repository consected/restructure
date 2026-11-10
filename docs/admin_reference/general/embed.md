# `embed`

## Direct Embedded Item

Embed a single related dynamic model record directly within this definition's form and display. The embedded item is looked up or linked via a foreign key field.

```yaml
!defs(extra_options_embed_defs.yaml)
```

### Pattern 1: Use the activity's default embedded resource

```yaml
!defs(extra_options_embed_pattern_1_default_defs.yaml)
```

### Pattern 2: Embed a specific resource by resource name string

```yaml
!defs(extra_options_embed_pattern_2_resource_name_defs.yaml)
```

### Pattern 3: Explicit Hash form for direct embed configuration

```yaml
!defs(extra_options_embed_pattern_3_hash_defs.yaml)
```

