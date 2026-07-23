# `embed`

## Direct Embedded Item

Embed a single related dynamic model record directly within this definition's form and display. The embedded item is looked up or linked via a foreign key field.

### Pattern 1: Default Embedded Resource

```yaml
!defs(extra_options_embed_pattern_1_default_defs.yaml)
```

### Pattern 2: Specific Resource Name

```yaml
!defs(extra_options_embed_pattern_2_resource_name_defs.yaml)
```

### Pattern 3: Explicit Hash Configuration

```yaml
!defs(extra_options_embed_pattern_3_hash_defs.yaml)
```

In hash form, the supported admin keys are `resource_name`, `resource_id`, and `limit`.
