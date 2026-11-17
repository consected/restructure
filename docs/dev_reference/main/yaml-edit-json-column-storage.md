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
- The current attribute value is passed to `Dynamic::FieldEditAs::ColTypeJson.display_value`,
  which dumps a `Hash` or `Array` value to a YAML string with `String.yaml_dump`, and
  renders it into a `code-editor-yaml` textarea (a CodeMirror YAML editor keyed by
  `data-code-editor-type: 'yaml'`). Any other value (`nil`, blank string, etc) renders
  as an empty textarea. This distinction matters because `#present?` is `false` for an
  empty `Hash`/`Array` as well as for a blank value - using `#present?` to decide whether
  to dump would make a stored `{}` or `[]` indistinguishable from "no value", both
  rendering blank and then being cleared to `nil` if the form were resubmitted unchanged.

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

A YAML document that parses to an empty string (for example `--- ''\n`) is also treated
as blank and returns `nil`, rather than raising. This specifically covers the display
template rendering a blank/absent value: `String.yaml_dump('')` produces the YAML
document `--- ''\n` rather than an empty string, so resubmitting the field unchanged
when it started blank must not raise.

## Related code

- [`app/models/dynamic/field_edit_as/handler.rb`](../../../app/models/dynamic/field_edit_as/handler.rb)
- [`app/models/dynamic/field_edit_as/col_type_json.rb`](../../../app/models/dynamic/field_edit_as/col_type_json.rb)
- [`app/views/common_templates/edit_fields/_column_type_json.html.erb`](../../../app/views/common_templates/edit_fields/_column_type_json.html.erb)
- [`app/views/common_templates/edit_fields/_column_type_jsonb.html.erb`](../../../app/views/common_templates/edit_fields/_column_type_jsonb.html.erb)
- [Admin field types reference](../../admin_reference/general/field_types.md) - see the
  `column_type_json` / `column_type_jsonb` rows in the Column Type Templates table.
