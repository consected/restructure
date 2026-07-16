# Edit Field Types Reference

This document describes all available edit field presentations used when rendering form fields in dynamic definitions. Fields are automatically matched to a presentation template based on their name, column type, and configuration. An `edit_as.field_type` override mechanism also allows explicit control over which template is used.

## Matching Priority Order

When rendering a form field, the system evaluates the field against the following matching rules **in priority order**. The first match wins.

1. **REDCap prefix** (highest priority, first checked) — if the field name starts with `redcap_` and exactly matches a REDCap template, that template is used.
2. **Name-exact match** — if a `name_is_{field_name}` template exists, it is used for that exact field name.
3. **Name-prefix match** — if the field name starts with `{prefix}_` and a `name_starts_with_{prefix}` template exists, it is used. Prefixes are sorted by length with the **longest match first**, so more specific prefixes take precedence.
4. **Name-suffix match** — if the field name ends with `_{suffix}` and a `name_ends_with_{suffix}` template exists, it is used. Suffixes are sorted by length with the **longest match first**, so more specific suffixes take precedence.
5. **respond_to_options** — if a helper method `{field_name}_options` exists, the field renders as a select dropdown populated by that method.
6. **GeneralSelection** — if a `Classification::GeneralSelection` record exists for the model and field, the field renders as a select dropdown with those options.
7. **External identifier** — if the model's `model_data_type == :external_identifier`, a specialized external ID input is rendered.
8. **Column type** — a `column_type_{type}` template is used based on the database column type (e.g. boolean, integer, date).
9. **Default fallback** — if no other match is found, the field renders as a standard text input.

## The `edit_as.field_type` Override

The `edit_as` configuration in `field_options` allows you to override the field name used for template matching. By setting `field_type`, the system replaces the field name with the specified value when evaluating matching rules. This overrides the field name for template matching, allowing any field to use any presentation regardless of its actual name.

Example configuration in the dynamic definition's `field_options`:

```yaml
my_custom_field:
  edit_as:
    field_type: select_status
```

This causes `my_custom_field` to be rendered as if it were named `select_status`, matching the `name_starts_with_select` template.

---

## REDCap Templates

REDCap templates match fields whose names start with `redcap_` and are the first priority in matching. These are used for fields synchronized from REDCap data dictionaries.

| Template | Renders | Notes |
|----------|---------|-------|
| `redcap_alpha_only` | Text input | Delegates to default text input |
| `redcap_completion_timestamp` | Fixed datetime | Read-only datetime display |
| `redcap_email` | Email text field | Validated email input |
| `redcap_file` | File link/display | Shows stored file with secure view link |
| `redcap_fixed` | Fixed/read-only | Hidden input with displayed value |
| `redcap_notes` | Textarea/rich text | Delegates to notes rendering |
| `redcap_phone` | Phone text field | Formatted phone input |
| `redcap_radio` | Select dropdown | Uses GeneralSelection or alt_options |
| `redcap_repeat` | Fixed/read-only | Read-only display |
| `redcap_select` | Select dropdown | Uses GeneralSelection or alt_options |
| `redcap_status` | Fixed/read-only | Read-only display |
| `redcap_survey_identifier` | Fixed/read-only | Read-only display |
| `redcap_tag_select` | Multi-select tags | Multiple selection with tag display |
| `redcap_time_mm_ss` | Text input | Time entry (minutes:seconds) |
| `redcap_true_false` | Radio buttons | true/false values |
| `redcap_yes_no` | Radio buttons | yes mapped to true, no mapped to false |
| `redcap_zip` | ZIP text input | ZIP code formatting |

## Name-Exact Match Templates (`name_is_*`)

These templates match when the field name is an exact match. For example, a field named `email` matches the `name_is_email` template.

| Template | Field Name | Renders | Notes |
|----------|-----------|---------|-------|
| `name_is_college` | `college` | Text input with typeahead | College name autocomplete |
| `name_is_country` | `country` | Country select dropdown | Uses country_select gem |
| `name_is_data` | `data` | Text input | Gets context from rec_type |
| `name_is_description` | `description` | Textarea/rich text | Delegates to notes |
| `name_is_e_signed_document` | `e_signed_document` | E-signature container | iframe with hidden textarea |
| `name_is_e_signed_how` | `e_signed_how` | Password + OTP fields | E-signature verification |
| `name_is_email` | `email` | Text input | Email validation |
| `name_is_message` | `message` | Textarea/rich text | Delegates to notes |
| `name_is_notes` | `notes` | Textarea or Markdown editor | Checks format option (plain or markdown) |
| `name_is_phone` | `phone` | Text input | Phone formatting |
| `name_is_protocol_event_id` | `protocol_event_id` | Select dropdown | Protocol events |
| `name_is_protocol_id` | `protocol_id` | Select dropdown | Protocols |
| `name_is_rank` | `rank` | Select or text | Uses GeneralSelection rank |
| `name_is_rec_type` | `rec_type` | Select dropdown | Uses GeneralSelection type |
| `name_is_source` | `source` | Select dropdown | Uses GeneralSelection source |
| `name_is_state` | `state` | Select dropdown | US states |
| `name_is_sub_process_id` | `sub_process_id` | Select dropdown | Sub-processes |
| `name_is_zip` | `zip` | Text input | ZIP formatting |

## Name-Prefix Match Templates (`name_starts_with_*`)

These templates match when the field name starts with a specific prefix. Prefixes are sorted by length so the **longest match first** (most specific first) takes precedence.

| Template | Pattern | Renders | Key Options |
|----------|---------|---------|-------------|
| `name_starts_with_select_record_id_from_table` | `select_record_id_from_table_{table}` | Select/big-select | value_attr, label_attr, big_select, creatable, sort_order, no_assoc |
| `name_starts_with_tag_select_record_from_table` | `tag_select_record_from_table_{table}` | Multi-select tags | value_attr, label_attr, sort_order, no_assoc |
| `name_starts_with_tag_select_record_id_from` | `tag_select_record_id_from_{model}` | Multi-select tags | label_attr, no_assoc, sort_order |
| `name_starts_with_pick_multiple_records_from_table` | `pick_multiple_records_from_table_{table}` | Grouped multi-select | Uses data field with pipe separator |
| `name_starts_with_tag_select_record_from` | `tag_select_record_from_{model}` | Multi-select tags | value_attr, label_attr, no_assoc, sort_order |
| `name_starts_with_select_record_id_from` | `select_record_id_from_{model}` | Select/big-select | label_attr, big_select, creatable, sort_order, no_assoc, select_filtering_target |
| `name_starts_with_select_record_from_table` | `select_record_from_table_{table}` | Select/big-select | value_attr, label_attr, big_select, creatable, sort_order, no_assoc, select_filtering_target |
| `name_starts_with_tag_select_users_with_role` | `tag_select_users_with_role_{role}` | Multi-select tags | Lists users with specific role |
| `name_starts_with_embedded_report_on_master_id` | `embedded_report_on_master_id_{id}` | Button/link | Opens report filtered by master_id |
| `name_starts_with_multi_editable_choices` | `multi_editable_choices_{name}` | YAML code editor | Stored as array |
| `name_starts_with_select_user_with_role` | `select_user_with_role_{role}` | Select dropdown | value_attr, label_attr |
| `name_starts_with_select_record_from` | `select_record_from_{model}` | Select/big-select | value_attr, label_attr, big_select, creatable, sort_order, no_assoc, select_filtering_target |
| `name_starts_with_multi_editable_list` | `multi_editable_list_{name}` | Textarea | One item per line, stored as array |
| `name_starts_with_redcap_tag_select` | `redcap_tag_select_{name}` | Multi-select tags | REDCap variant of tag selection |
| `name_starts_with_embedded_report` | `embedded_report_{id}` | Button/link | Opens report filtered by record id |
| `name_starts_with_tag_select` | `tag_select_{name}` | Multi-select tags | Uses GeneralSelection or alt_options |
| `name_starts_with_placeholder` | `placeholder_{name}` | Empty placeholder | Hidden label, empty span |
| `name_starts_with_e_signed` | `e_signed_{name}` | Fixed/read-only | Hidden input with displayed value |
| `name_starts_with_hidden` | `hidden_{name}` | Hidden input | Completely hidden from UI |
| `name_starts_with_select` | `select_{name}` | Select dropdown | Uses GeneralSelection or alt_options, select_filtering_target |
| `name_starts_with_multi` | `multi_{name}` | Multi-select | Same as select but with multiple |
| `name_starts_with_fixed` | `fixed_{name}` | Fixed/read-only | Hidden input with shown text value |

## Name-Suffix Match Templates (`name_ends_with_*`)

These templates match when the field name ends with a specific suffix. Suffixes are sorted by length so the **longest match first** (most specific first) takes precedence.

| Template | Pattern | Renders | Notes |
|----------|---------|---------|-------|
| `name_ends_with_blank_yes_no_dont_know` | `*_blank_yes_no_dont_know` | Radio buttons | (not set), yes, no, don't know |
| `name_ends_with_blank_yes_no` | `*_blank_yes_no` | Radio buttons | (not set), yes, no |
| `name_ends_with_yes_no_dont_know` | `*_yes_no_dont_know` | Radio buttons | yes, no, don't know; include_blank optional |
| `name_ends_with_description` | `*_description` | Textarea/rich text | Delegates to notes |
| `name_ends_with_true_false` | `*_true_false` | Radio buttons | true, false |
| `name_ends_with_selection` | `*_selection` | Select dropdown | Delegates to select |
| `name_ends_with_details` | `*_details` | Textarea/rich text | Delegates to notes |
| `name_ends_with_yes_no` | `*_yes_no` | Radio buttons | yes, no |
| `name_ends_with_no_yes` | `*_no_yes` | Radio buttons | no, yes (reversed order) |
| `name_ends_with_notes` | `*_notes` | Textarea/rich text | Delegates to notes |
| `name_ends_with_year` | `*_year` | Number input | 4-digit year |
| `name_ends_with_date` | `*_date` | Date input | Date input or datetime combo |
| `name_ends_with_link` | `*_link` | URL input | Delegates to url |
| `name_ends_with_rank` | `*_rank` | Select or rank field | Uses GeneralSelection rank |
| `name_ends_with_time` | `*_time` | Time text input | Time entry field |
| `name_ends_with_when` | `*_when` | Date/datetime input | Delegates to date |
| `name_ends_with_url` | `*_url` | URL input | URL field |

## Special Templates

These templates are triggered by conditions other than field name patterns.

| Template | Trigger | Renders | Notes |
|----------|---------|---------|-------|
| `respond_to_options` | A helper method `{field_name}_options` exists | Select dropdown | Options populated by the helper method |
| `is_general_selection` | A `Classification::GeneralSelection` record exists for the model and field | Select dropdown | Options from general_selection configuration |
| `is_external_id` | The model is an external identifier (`model_data_type == :external_identifier`) | Text/number input | External ID entry |
| `default` | No other match found (fallback) | Text input | Standard text input field |

## Column Type Templates

These templates match based on the database column type when no name-based or special match is found.

| Template | Column Type | Renders | Notes |
|----------|-------------|---------|-------|
| `column_type_boolean` | boolean | Checkbox | |
| `column_type_date` | date | Date input | |
| `column_type_datetime` | datetime | Date + time combo | |
| `column_type_decimal` | decimal | Number input (step: any) | |
| `column_type_float` | float | Number input (step: any) | |
| `column_type_integer` | integer | Number input (step: 1) | |
| `column_type_json` | json | YAML code editor | Non-blank input must be a YAML Hash or Array; leave blank to clear the field. [Details](../../dev_reference/main/yaml-edit-json-column-storage.md) |
| `column_type_jsonb` | jsonb | YAML code editor | Non-blank input must be a YAML Hash or Array; leave blank to clear the field. [Details](../../dev_reference/main/yaml-edit-json-column-storage.md) |

## Sub-Templates

These templates are not matched directly by the field matching logic. Instead, they are rendered by other templates as shared components.

| Template | Used By | Renders |
|----------|---------|---------|
| `button_radio` | yes/no, true/false, and other radio variants | Radio buttons styled as a button group |
| `creatable_select_input` | select_record_* templates when creatable is enabled | Typeahead text input for creating new records |

## `field_options` and `edit_as` Attribute Reference

### Select and Radio Field Options

These attributes apply to `select_*`, `tag_select_*`, `multi_*` and radio button fields.

- `alt_options` — provide inline options instead of looking up a `GeneralSelection` list.
  Accepts a hash `{'Display Label': stored_value, ...}` or an array `['Label', ...]`.
  With an array, each label is automatically downcased to produce the stored value.
- `general_selection` — use a GeneralSelection definition with an alternative name,
  or one belonging to a different model prefix. Overrides the default lookup by model + field name.
- `include_blank` — `true` or `false`. Forces a selectable blank/empty option in dropdowns
  and radio button groups. Some field types (e.g. `blank_yes_no`) always include a blank.
- `prompt` — placeholder text displayed in select fields when no value is selected.

### Record-Based Select Options (`select_record_*`)

These attributes apply to fields that select from dynamic model records
(`select_record_from_*`, `select_record_id_from_*`, `tag_select_record_*`,
`pick_multiple_records_from_table_*`).

- `value_attr` — the record attribute to store as the field value.
  Defaults to the record's display value. Use `id` to store the record's primary key.
- `label_attr` — the record attribute(s) to display as the option label.
  Can be a single attribute name (`name`) or an array for composite labels
  (`[category, '|', name]`). See `group_split_char` and `big_select.hide_key` for
  how separators in label_attr are processed.
- `sort_order` — sort order for options, specified as `"attribute direction"`.
  For example: `"value desc"` or `"label asc"`. Default is `"label asc"`.
- `no_assoc` — `true` or `false`. When `true`, skips the ActiveRecord association lookup
  and queries the table directly. Defaults to `true` for `_table_` variants
  (e.g. `select_record_from_table_*`). Defaults to `false` for association-based variants
  (e.g. `select_record_from_*`), but can be overridden.
- `group_split_char` — a character in the label used to split options into collapsible
  groups. For example, with `label_attr: [category, '|', name]` and
  `group_split_char: '|'`, items are grouped by `category` with `name` shown inside
  each group.
- `select_filtering_target` — the name of another field whose options should be
  filtered when this field's value changes. Used in combination with
  `big_select.filtered` on the target field. The filter value is passed to the target
  via its `blank_preset_value` configuration.

### `big_select` — Modal Dialog Selection

Applies to `select_record_*` fields. Instead of a standard dropdown, the field opens
a full-screen modal dialog providing a searchable, scrollable list — better suited for
large option sets.

Configure as a hash under `edit_as`:

```yaml
field_options:
  my_field:
    edit_as:
      field_type: select_record_from_table_some_items
      value_attr: id
      label_attr: name
      big_select:
        hide_key: true
```

Sub-options:

- `hide_popover` — `true` or `false` (default: `false`).
  When `true`, hides the info popover button next to the field and instead shows an
  overlay displaying the currently selected value's text. This provides inline feedback
  without requiring the user to hover or click an info icon.

- `hide_key` — `true` or `false` (default: `true`).
  Controls whether the record's database key (ID) is visible in the selection list.
  When `true`:
  - The key is hidden from the display.
  - If `label_attr` contains a `' >>> '` or `'\n'` separator, the label is split:
    the first part appears as the **primary heading** (larger text) and the remaining
    parts appear as a **secondary description** (smaller text below).
  - Without a separator, the entire label is shown as the heading.

  When `false`:
  - The key is shown alongside the full label text.
  - No `>>>` / `\n` separator processing is applied.

  Example with `>>>` separator for two-part display:
  ```yaml
  edit_as:
    field_type: select_record_from_table_some_items
    value_attr: id
    label_attr:
      - name
      - ' >>> '
      - description
    big_select:
      hide_key: true
  # Displays as:
  #   Item Name          ← primary heading (larger)
  #   Item description   ← secondary text (smaller)
  ```

- `filtered` — `true` or `false` (default: `false`).
  When `true`, the big-select options are dynamically filtered based on another field's
  value. Requires a companion field configured with `select_filtering_target` pointing
  to this field, and a `blank_preset_value` on this field that injects the filter value
  into the query.

  Example filtered configuration:
  ```yaml
  field_options:
    filter_field:
      edit_as:
        field_type: select_filter_values
        alt_options:
          'Category A': category_a
          'Category B': category_b
        select_filtering_target: 'my_select_field'

    my_select_field:
      edit_as:
        field_type: select_record_from_table_some_items
        value_attr: id
        label_attr:
          - item_type
          - '|'
          - name
        group_split_char: '|'
        big_select:
          filtered: true
      blank_preset_value:
        table_name:
          filter_field_name: "{{filter_field}}"
  ```

  When the user selects "Category A" in `filter_field`, the big-select dialog for
  `my_select_field` shows only items where `filter_field_name` matches `category_a`.
  Changing the filter value updates the available options dynamically.

Grouped big-select example (using `group_split_char` with big-select):
```yaml
edit_as:
  field_type: select_record_from_table_some_items
  value_attr: id
  label_attr:
    - category
    - '|'
    - name
  group_split_char: '|'
  big_select:
    hide_key: true
```
Items are displayed in collapsible groups by `category`. When editing an existing
record, the group containing the currently selected value is automatically expanded.
A `(none)` option at the bottom of the list allows clearing the selection.

### `creatable` — Typeahead with Record Creation

Applies to `select_record_from_table_*` fields. Instead of a dropdown or big-select
dialog, the field renders as a **typeahead text input** backed by existing records.
If the user types a value that does not match any existing record, a new record is
automatically created in the source table when the form is saved.

```yaml
field_options:
  my_field:
    edit_as:
      field_type: select_record_from_table_some_items
      value_attr: name
      label_attr: name
      creatable:
        enabled: true
```

- `creatable.enabled` — `true` or `false` (default: `false`).
  When `true`, the field renders as a typeahead text input with autocomplete
  suggestions from the source table's existing records.
  The user must have **create access** on the source dynamic model for new records
  to be created. If the user lacks create access, they can only select from
  existing items (the typeahead still functions, but unmatched values are rejected).

### Text and Notes Field Options

These attributes apply to text inputs and textarea/notes fields.

- `format` — `plain` or `markdown`. Controls the editor type for notes, description,
  details, and message fields. `plain` renders a standard `<textarea>`.
  `markdown` renders a rich Markdown editor with toolbar. Default is determined by the
  app configuration `notes_field_format`.
- `config.toolbar_type` — set to `advanced` to add additional editor toolbar controls
  to the Markdown editor (only applies when `format: markdown`).
- `pattern` — an HTML5 validation regex pattern for text inputs.
  Example: `'.+\\d{3}-\\D{1-4}.*'` accepts one or more characters, 3 digits, a hyphen,
  1-4 letters, and any remaining characters.

### Default Value Options

These attributes control initial and computed field values.

- `value` — default value for new (unsaved) records, set in the form UI only.
  Accepts literal values, `now()`, or `today()`.
  Not applied if a `preset_value` is set. Not available for data conditions.
- `blank_value` — default value applied in the form UI when the record exists but the
  field is currently blank. Accepts literal values, `now()`, or `today()`.
- `preset_value` — default value set when building model instances (before rendering).
  Accepts literal values, `now()`, `today()`, or `{{substitutions}}`.
  Can drive logic such as `embed_resource_name`. Not applied to persisted instances.
- `blank_preset_value` — like `preset_value`, but only applied when the attribute is blank.
  Also used to pass filter values for `big_select.filtered` configurations.
- `active_value` — value set whenever an instance is initialized. Allows live substitutions
  from other models. Persisted on save; re-evaluated on each access.

### Display and Storage Options

- `no_downcase` — `true` to prevent automatic downcasing when storing to the database.
  By default, string fields are downcased on storage and titleized on display.
- `view_original_case` — `true` to prevent the UI from capitalizing downcased field values.
- `view_with_formats` — a list of formatters to apply to a string field when viewed.
- `calculate_with` — a calculation expression for computed fields.
  Example: `calculate_with: { sum: [field_a, field_b] }` automatically sums two fields.
- `use_app_type` — use a specific app type (by ID or name) instead of the user's current
  app type when filtering protocol selections.
