# `full_text_search`

## Build and Persist Full Text Search Indexes

Use this save trigger to build text from model fields and persist PostgreSQL `tsvector` data for search.

This trigger supports two write modes:

- Same-table mode: writes to a `tsvector` column on the current record table
- Separate-table mode: upserts into a target table using a foreign key reference

## Configuration

### Same-table mode

```yaml
save_trigger:
  on_save:
    full_text_search:
      - index_this:
          target_column: search_index
          source_fields:
            - title
            - description
          ts_config: english
```

### Separate-table mode

```yaml
save_trigger:
  on_save:
    full_text_search:
      - index_target:
          target_table: dynamic_test.record_search_indexes
          target_column: search_vector
          target_foreign_key_column: source_record_id
          source_fields:
            - title
            - description
            - notes
          extra_content: '{{external_identifiers.reference_text}}'
          ts_config: english
```

## Options

- `source_fields`: required array of field names used to build text content
- `target_column`: required tsvector field to update
- `target_table`: optional; if omitted, writes to current record table
- `target_foreign_key_column`: required when `target_table` is set
- `extra_content`: optional additional text appended to indexed content
- `ts_config`: optional PostgreSQL text search configuration (defaults to `english`)

## Requirements

- Target `tsvector` columns must exist before trigger execution.
- Use a `gin` index on `tsvector` fields for report performance.
- Ensure the trigger runs on events where source text is finalized (`on_save` is typical).

See also: [Full Text Search](full_text_search.md)
