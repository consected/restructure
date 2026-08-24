# `full_text_search`

## Build and Persist Full Text Search Indexes

Use this save trigger to build text from model fields and persist PostgreSQL `tsvector` data for search.

This trigger supports two write modes:

- Same-table mode: writes to a `tsvector` column on the current record table
- Separate-table mode: upserts into a target table using a foreign key reference

## Configuration

```yaml
!defs(save_triggers_full_text_search_options_defs.yaml)
```

### Pattern 1: Same-table mode

```yaml
!defs(save_triggers_full_text_search_pattern_1_same_table_defs.yaml)
```

### Pattern 2: Separate-table mode

```yaml
!defs(save_triggers_full_text_search_pattern_2_separate_table_defs.yaml)
```

## Requirements

- Target `tsvector` columns must exist before trigger execution.
- Use a `gin` index on `tsvector` fields for report performance.
- Ensure the trigger runs on events where source text is finalized (`on_save` is typical).

See also: [Full Text Search](full_text_search.md)
