# `generate_document`

## Generate a Document from a Template

Render content from a template and store the resulting document as a file in an NFS filestore container.
Uses the same template mechanisms as the `notify` trigger for content generation, and stores
the rendered output using `NfsStore::Import.import_file`.

Common use cases:

- Generating letters, reports, or summaries when a record is saved
- Creating documents that can be reviewed before sending
- Producing files that a subsequent `notify` trigger can attach to an email
- Automating document creation in case management workflows (activity logs)

```yaml
!defs(save_triggers_generate_document_options_defs.yaml)
```

### Pattern 1: Named content template, container via model reference

```yaml
!defs(save_triggers_generate_document_pattern_1_named_template_defs.yaml)
```

### Pattern 2: Inline content_template_text with layout and extra_substitutions

`content_template_text` is used instead of `content_template_name` when the content isn't
worth storing as a separate named template.

```yaml
!defs(save_triggers_generate_document_pattern_2_inline_text_defs.yaml)
```

### Pattern 3: Resolve the container by name or id

```yaml
!defs(save_triggers_generate_document_pattern_3_container_lookup_defs.yaml)
```

### Container Resolution

The `container` configuration determines which NFS filestore container the generated document
is stored in. Two resolution mechanisms are supported:

- **Model reference** (`from_this: model_reference`): Looks up a container referenced by the current
  item via `ModelReference`. This is the common pattern when a `create_filestore_container` trigger
  was used earlier in the trigger chain.
- **Named lookup** (`name: 'container-name'`): Finds a container by name within the current master record.
  Supports `{{curly}}` substitutions in the name.
- **ID lookup** (`id: container_id`): Finds a container directly by its database ID.
  Supports `{{curly}}` substitutions in the value.

### Content Generation

Content is generated using `Admin::MessageTemplate`, consistent with the `notify` trigger:

- **Named template** (`content_template_name`): Looks up a content template by name.
- **Inline text** (`content_template_text`): Uses the provided text directly. Supports `{{curly}}` substitutions.
- **Layout wrapping** (`layout_template`): Wraps the rendered content in a layout template, replacing `{{main_content}}`.
- **Extra substitutions** (`extra_substitutions`): Provides additional data for `{{extra_substitutions.*}}` tags.

### Trigger Results

After successful document generation, results are stored in
`save_trigger_results['generate_document']` with the following keys:

- `container_id`: The ID of the container where the file was stored
- `filename`: The resolved filename
- `stored_file_id`: The ID of the stored file record
- `path`: The subdirectory path (if specified)
- `content_type`: The MIME type of the stored file

These results can be referenced by subsequent triggers using
`{{save_trigger_results.generate_document.stored_file_id}}` etc.

### User Context

The `store_as_user` and `store_in_app_type` options configure the user and app type context
for the file store operation, following the same pattern as the `notify` trigger's batch user
configuration.

### Duplicate File Handling

- `skip_existing: true`: If a file with the same name and path exists, skip the import
- `replace: true`: If a file with the same name and path exists but has different content, replace it
