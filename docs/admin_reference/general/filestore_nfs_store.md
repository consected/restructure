# `nfs_store`

## NFS Filestore Configuration

Configure how an NFS filestore container responds to uploads, file actions, and access control within this activity log. Includes pipeline jobs, user file actions, and conditional access.

```yaml
!defs(filestore_nfs_store_defs.yaml)
```

## Full Text Search Pipeline Step

Use the `full_text_search` pipeline step to extract text from supported uploaded files and write searchable `tsvector` data to a target table.

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

### Configuration fields

- `target_table`: schema-qualified table storing search vectors
- `target_column`: `tsvector` column to update
- `target_foreign_key_column`: FK column that identifies the source stored file
- `ts_config`: PostgreSQL text search configuration, such as `english` or `simple`
- `file_filters`: optional list of regex filters. If set, only matching files are indexed.

`file_filters` follows the same regex list pattern used by `scripted` and `dicom_deidentify` pipeline jobs.

See also: [Full Text Search](full_text_search.md)
