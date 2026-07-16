# Editing json/jsonb Columns as YAML Text

Dynamic definitions (dynamic models, activity logs, external identifiers) can include
attributes backed by a `json` or `jsonb` database column. Rather than exposing raw JSON
to the user, ReStructure presents these columns as a YAML code editor, since YAML is
more compact and readable for hand-editing hashes and arrays than JSON is.

This document describes how the display (JSON/jsonb → YAML) and save (YAML → JSON/jsonb)
translation works, and how it is wired together.

## Display: column value → YAML text

- `app/views/common_templates/edit_fields/_column_type_jsonb.html.erb` is the template
  used to render the field. It is matched automatically by column type: a field backed
  by a `jsonb` column resolves to `column_type_jsonb`, and a field backed by a `json`
  column resolves to `column_type_json`.
- `app/views/common_templates/edit_fields/_column_type_json.html.erb` simply renders the
  `_column_type_jsonb` partial, so both column types share one implementation.
- The current attribute value (already a Ruby `Hash` or `Array`, since it was loaded from
  a json/jsonb column) is converted to a YAML string with `String.yaml_dump` and rendered
  into a `code-editor-yaml` textarea (a CodeMirror YAML editor keyed by
  `data-code-editor-type: 'yaml'`).

## Save: YAML text → persistable column value

- On submit, the field arrives as a plain YAML-formatted string parameter, matching
  whatever the user typed into the editor.
- `Dynamic::FieldEditAs::Handler#translate_to_persistable` (see
  `app/models/dynamic/field_edit_as/handler.rb`) is called from
  `MasterHandler#translate_params_to_persistable` (and applied likewise to any
  embedded item) before the params are assigned to the model.
- For each attribute, the handler determines its `edit_as` field type - defaulting to
  `"col_type_#{column.type}"` when no explicit `field_options.edit_as.field_type` is
  configured. This yields `col_type_json` for `json` columns and `col_type_jsonb` for
  `jsonb` columns.
- `Handler::TransformFieldTypes` only lists `col_type_json`, and the match against a
  field's resolved type is done with `include?` (substring match), not equality. This
  means `col_type_jsonb`.include?(`col_type_json`) is `true`, so both `json` and `jsonb`
  columns are routed to the same translation class.
- `Dynamic::FieldEditAs::ColTypeJson.persistable_value` (see
  `app/models/dynamic/field_edit_as/col_type_json.rb`) parses the submitted YAML string
  with `YAML.safe_load`. It accepts the parsed value only when it is already a top-level
  `Hash` or `Array`; that object is what gets persisted into the json/jsonb column.

## Accepted input

Non-blank YAML documents must have a top-level Hash or Array. Any other value
(including a bare scalar, `null`, `false`, malformed YAML, or YAML aliases rejected
by `YAML.safe_load`) raises an `FphsException` from `ColTypeJson.persistable_value`.
A blank field returns `nil`, allowing the normal model assignment to clear the column.

## Related code

- [`app/models/dynamic/field_edit_as/handler.rb`](../../../app/models/dynamic/field_edit_as/handler.rb)
- [`app/models/dynamic/field_edit_as/col_type_json.rb`](../../../app/models/dynamic/field_edit_as/col_type_json.rb)
- [`app/views/common_templates/edit_fields/_column_type_json.html.erb`](../../../app/views/common_templates/edit_fields/_column_type_json.html.erb)
- [`app/views/common_templates/edit_fields/_column_type_jsonb.html.erb`](../../../app/views/common_templates/edit_fields/_column_type_jsonb.html.erb)
- [Admin field types reference](../../admin_reference/general/field_types.md) - see the
  `column_type_json` / `column_type_jsonb` rows in the Column Type Templates table.
