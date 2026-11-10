# `reload_this`
## Reload the Current Record

Reload the current record from the database after other trigger tasks have run, ensuring downstream triggers see the latest persisted state.

Particularly useful when:

1. Working with views where `view_sql` includes joins to other tables that may have been
   updated by previous triggers.
2. After `create_reference` or `update_reference` triggers that modify related data which
   affects the current item's attributes.
3. When subsequent triggers need `this.attribute` conditions or `{{attribute}}`
   substitutions that reflect recent changes.

Without `reload_this`, `{{attribute}}` substitutions and `this.attribute` conditions show
the original values from when the trigger pipeline started.

```yaml
!defs(save_triggers_reload_this_options_defs.yaml)
```

### Pattern 1: Reload between two dependent triggers

```yaml
!defs(save_triggers_reload_this_pattern_1_basic_defs.yaml)
```

