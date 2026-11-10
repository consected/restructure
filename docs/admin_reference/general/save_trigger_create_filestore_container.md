# `create_filestore_container`
## Create an NFS Filestore Container

Create a named NFS filestore container and its associated reference when this trigger fires. See also the [filestore save_trigger](filestore_save_trigger.md) for the standard configuration.

```yaml
!defs(save_triggers_create_filestore_container_options_defs.yaml)
```

### Pattern 1: Name from a literal/substituted string

```yaml
!defs(save_triggers_create_filestore_container_pattern_1_basic_defs.yaml)
```

### Pattern 2: Name built from a list of attribute names

Each entry is resolved against the item's attributes (falling back to the literal value if no
matching attribute is found) and joined with ` -- `.

```yaml
!defs(save_triggers_create_filestore_container_pattern_2_attribute_list_defs.yaml)
```

