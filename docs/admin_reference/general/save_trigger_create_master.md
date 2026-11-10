# `create_master`
## Create a Master Record

Create a new master record when this trigger fires.

```yaml
!defs(save_triggers_create_master_options_defs.yaml)
```

### Pattern 1: Create a new master record

```yaml
!defs(save_triggers_create_master_pattern_1_basic_defs.yaml)
```

### Pattern 2: Create and move the current item to the new master

`move_this: true` reassigns the current item (and any embedded item) to the newly created
master, instead of leaving it under its original master.

```yaml
!defs(save_triggers_create_master_pattern_2_move_this_defs.yaml)
```

