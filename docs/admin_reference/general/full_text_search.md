# Full Text Search

## Overview

Full text search combines extracted raw text with PostgreSQL full text indexing and SQL querying.

Typical flow:

1. Raw text is collected from dynamic definition instances (save trigger source fields) and/or files uploaded to Filestore.
2. The text is written into `tsvector` indexes, usually in a dedicated target table with a foreign key back to the source record or stored file.
3. Reports join to indexed tables and use PostgreSQL full text SQL operators to include text search results in broader queries.

## End-to-End Configuration

Full text search in ReStructure is configured across three layers:

1. Define `tsvector` storage in the database
2. Populate indexed text using save triggers and/or filestore pipeline jobs
3. Query indexed content from reports using PostgreSQL full text search operators

## Define Search Vector Storage

Use `_db_columns` definitions to create `tsvector` columns and `gin` indexes where needed.

```yaml
_db_columns:
  search_index:
    type: tsvector
    index: gin
```

You may index directly on the source table, or store vectors in a separate target table with an FK to the source record or stored file.

See also: [db_columns](db_columns.md)

## Populate Index Data

### Save trigger indexing (record fields)

Use the `full_text_search` save trigger to build text from record fields and write to a target `tsvector` column.

```yaml
save_trigger:
  on_save:
    full_text_search:
      - index_this:
          target_column: search_index
          source_fields:
            - title
            - body
          ts_config: english
```

For writing to a separate target table:

```yaml
save_trigger:
  on_save:
    full_text_search:
      - index_to_target:
          target_table: dynamic_test.item_search_indexes
          target_column: search_vector
          target_foreign_key_column: source_record_id
          source_fields:
            - title
            - body
            - notes
          ts_config: english
```

See also: [Save Trigger: full_text_search](save_trigger_full_text_search.md)

### Filestore pipeline indexing (uploaded file text)

Use `nfs_store.pipeline.full_text_search` to extract text from supported files and write search vectors.

```yaml
nfs_store:
  pipeline:
    - mount_archive:
    - index_files:
    - full_text_search:
        target_table: dynamic_test.file_search_indexes
        target_column: search_vector
        target_foreign_key_column: stored_file_id
        ts_config: english
        file_filters:
          - '.*\\.txt$'
          - '.*\\.pdf$'
```

`file_filters` is optional. If set, only files matching one of the regex filters are indexed.

See also: [Filestore nfs_store configuration](filestore_nfs_store.md)

## Query in Reports

Reports can search indexed data by joining to the target table and applying full-text operators.

```sql
select dm.id, dm.title
from dynamic_test.my_items dm
join dynamic_test.item_search_indexes idx
  on idx.source_record_id = dm.id
where :search_text is null
   or idx.search_vector @@ plainto_tsquery('english', :search_text)
```

See also: [Reports: Full Text Search](../reports/full_text_search.md)

## Operational Notes

- Use `simple` when stemming should be disabled.
- Keep source text concise and relevant; avoid indexing large low-signal fields.
- Ensure a `gin` index exists on `tsvector` columns used in report queries.
