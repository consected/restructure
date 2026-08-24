# `add_tracker`
## Add Tracker Entry

Add a tracker entry (protocol event) when this trigger fires.

```yaml
!defs(save_triggers_add_tracker_options_defs.yaml)
```

### Pattern 1: Basic tracker using the entry label as the protocol name

The entry label (`Q1` here) is used to resolve the `Classification::Protocol` when
`with:` doesn't specify `protocol_name`/`protocol_id`.

```yaml
!defs(save_triggers_add_tracker_pattern_1_basic_defs.yaml)
```

### Pattern 2: Explicit protocol_name/protocol_id

Use `with.protocol_name` or `with.protocol_id` when the entry label isn't itself a
valid protocol name - the entry label can then be any convenient identifier.

```yaml
!defs(save_triggers_add_tracker_pattern_2_explicit_protocol_defs.yaml)
```

### Pattern 3: Target a different item/master

By default the tracker is tied to the current item and its master. Set `item_type`/`item_id`
and/or `master_id` to tie the tracker to a different record instead.

```yaml
!defs(save_triggers_add_tracker_pattern_3_alternative_target_defs.yaml)
```

