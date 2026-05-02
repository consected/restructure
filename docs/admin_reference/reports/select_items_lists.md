# Select Items: Checkbox Actions in Reports

Reports can display a checkbox next to each row, letting users tick multiple records and
perform a bulk action on all checked rows in one submission. This is used by the file-download
feature (via NFS Store) and by list-building workflows such as bulk messaging and data-variable
selection.

The feature is activated entirely through the **column alias** of a special SQL column. No
additional report options or admin-panel toggles are required.

---

## Action variants

Alias the checkbox SQL column with one of the following patterns (the column name is what appears
in the SQL `SELECT` after the expression, between double-quotes):

| Column alias | Bulk action |
|---|---|
| `select items: download files` | POST selected files to `/nfs_store/downloads/multi` |
| `select items: add to list: <list_table>` | POST to `/reports/:id/add_to_list` — inserts new records into the list table |
| `select items: update list: <list_table>` | POST to `/reports/:id/update_list` — inserts new selections **and** disables removed ones |
| `select items: remove from list: <list_table>` | POST to `/reports/:id/remove_from_list` — disables selected records in the list table |

`<list_table>` must be the plural snake_case table name of the model that stores user selections
(e.g. `data_requests_selected_attribs` or `zeus_bulk_message_recipients`).

For the `download files` variant see [File Filtering](file_filtering.md).

The rest of this document covers the three **list** variants (`add to list`, `update list`,
`remove from list`).

---

## How the UI works

When a report result contains a `select items:` column the JavaScript function
`results_select_items_for_form` (in `app/assets/javascripts/app/reports.js`):

1. Renders each cell value as a checkbox (checked when `init_value` is `true`).
2. Injects **Select all / Unselect all** links into the column header.
3. Wraps the results table in a `<form id="itemselection-for-report">`.
4. Auto-submits the form to the appropriate endpoint whenever any checkbox is changed.

---

## The list table

The model that stores user selections (the *list table*) must have the following columns:

| Column | Type | Notes |
|---|---|---|
| `id` | integer (PK) | Standard Rails primary key |
| `master_id` | integer (FK) | Optional; omit for no-master models |
| `record_type` | string | The singular class name of the source model |
| `record_id` | integer | The `id` of the selected source row |
| `<grouping_fk>` | integer | A FK tying all selections to one parent record, e.g. `data_request_id` or `zeus_bulk_message_id`. The attribute name is detected automatically as the first `_id` FK column that is not `id`, `master_id`, `record_id`, or `user_id`. |
| `disabled` | boolean | `true` when the user has un-ticked the item (soft-delete). Must have a default of `false`. |
| *(extra fields)* | any | Any fields with names matching columns in the source table are automatically copied when a new selection is inserted. |

The list table is typically set up as a **Dynamic Model** (see the Dynamic Models admin panel).

### Example Dynamic Model columns

```
id, master_id, data_request_id, record_type, record_id, variable_name, disabled, user_id, created_at, updated_at
```

---

## User access controls

The submitting user must have the following access controls configured:

| Resource | Access level | Why |
|---|---|---|
| The **list table** (e.g. `data_requests_selected_attribs`) | `create` | To insert/update selection records |
| The **source table** being selected from | `access` | To read the source rows |
| The **parent record** identified by `list_id` | — | Authorised through the normal master/record access mechanism |

The user must also have `view_reports` or `view_report_not_list` capability.

---

## JSON column value format

Each cell in the `select items:` column must contain a JSON object (cast to text in SQL):

```json
{
  "field_name": "update_list[items][]",
  "label": "optional checkbox label",
  "value": {
    "list_id": "<id>",
    "type": "<source_table>",
    "id": <source_row_id>,
    "from_master_id": <master_id_or_-1>,
    "init_value": true
  }
}
```

| Field | Required | Notes |
|---|---|---|
| `field_name` | Yes | Must match the action variant: `"add_to_list[items][]"`, `"update_list[items][]"`, or `"remove_from_list[items][]"`. The form auto-submits to `/reports/:id/<action>` and Rails param-nesting requires the matching prefix. |
| `label` | No | Text shown next to the checkbox. Omit for no label. |
| `value.list_id` | Yes | The integer ID of the parent record (e.g. the `data_request_id` value) |
| `value.type` | Yes | The plural snake_case table name of the **source** table (e.g. `"q2_datadic"`) |
| `value.id` | Yes | The row id this checkbox represents. For `add to list` and `update list` this is the **source row's** id (it is stored as `record_id` in the list table). For `remove from list` this is the **list row's** primary key id (the row to be disabled). See the [`remove from list` example](#remove-from-list-example) below. |
| `value.from_master_id` | Yes | The `master_id` of the record context, or `-1` when not applicable |
| `value.init_value` | Yes | `true` if the item is already in the list (checkbox shown as checked); `false` otherwise |
| `value.on_attr` | No | Override the column used to match against `list_id`. Defaults to `"id"`. Use `"master_id"` to group selections by master record rather than a specific list record. |

Multiple checkboxes in a single cell are supported by providing a JSON array instead of a single
object.

---

## Required report SQL structure

A report enabling `update list` selections must:

1. **Return the source rows** (the records users will tick).
2. **Have a `:list_id` search parameter** (typically a hidden integer field) to scope
   selections to a specific parent record.
3. **Include the JSON checkbox column** aliased `"select items: update list: <list_table>"`.
4. **Left-join the list table** so that already-selected items have their checkbox pre-checked
   (`init_value: true`).

---

## Full SQL example (`update list`)

The following example shows how to build a variable-selection report where users pick
variables from a data dictionary (`q2_datadic`) for a specific data request, and the
selections are stored in `data_requests_selected_attribs`.

```sql
select distinct
  source.id,

  -- Checkbox column: tells the UI which record to add/remove from the list table
  '{"field_name": "update_list[items][]",' ||
  '"value": {"list_id": "' || :list_id || '",' ||
    '"type":"q2_datadic",' ||
    '"id": ' || source.id || ',' ||
    '"from_master_id":-1,' ||
    '"init_value": ' ||
      case when coalesce(selections.id, 0) = 0 then 'false' else 'true' end
    || '} }'
    "select items: update list: data_requests_selected_attribs",

  -- This field is also present in the list table and will be copied on insert
  source.variable_name,

  -- Other visible columns
  source.field_label,
  case when coalesce(selections.id, 0) = 0 then 'false' else 'true' end "selected"

from q2_datadic source

-- Left join so pre-existing selections show as checked
left join data_requests_selected_attribs selections
  on selections.record_id = source.id
  and selections.record_type = 'q2_datadic'
  and not coalesce(selections.disabled, false)
  and :list_id = selections.data_request_id

where
  -- Optional filtering of source data; does not affect the list logic
  (
    :name_or_label_contains is NULL
    OR source.variable_name ~* :name_or_label_contains
    OR source.field_label ~* :name_or_label_contains
  )
  OR selections.id IS NOT NULL

order by
  -- Show already-selected items at the top
  selected desc, source.id;
```

The `:list_id` and `:name_or_label_contains` parameters would be configured in the report's
**Search Attributes** (see [SQL Search Attributes](search_attributes.md)). A typical setup hides
`:list_id` from the user and passes it via a preset or URL parameter.

---

## `remove from list` example

Unlike `add to list` and `update list`, a `remove from list` report queries **the list table
itself** and submits each list row's primary key in `value.id`. The server then disables those
list rows directly.

```sql
select
  '{"field_name": "remove_from_list[items][]",' ||
  '"value": {"list_id": "' || :list_id || '",' ||
    '"type":"player_contacts",' ||
    '"id":' || b.id || ',' ||
    '"from_master_id":-1} }'
    "select items: remove from list: zeus_bulk_message_recipients",
  pi.first_name "first name",
  pi.last_name  "last name",
  b.data        "phone"
from zeus_bulk_message_recipients b
inner join player_contacts pc on pc.id = b.record_id
inner join player_infos     pi on pi.master_id = pc.master_id
where b.zeus_bulk_message_id = :list_id
  and b.disabled = false
order by b.data;
```

Note that `b.id` (the `zeus_bulk_message_recipients` PK) is what populates the JSON `id` field —
not `pc.id` (the source row id). The `type` field still names the source table for display
purposes only.

---

## `add to list` vs `update list` vs `remove from list`

| Variant | Behaviour |
|---|---|
| `add to list` | Inserts only **new** selections. Raises an error if all submitted items are already in the list. Existing selections are never modified. |
| `update list` | Inserts new selections **and** disables (soft-deletes) any previously-selected items whose checkbox is now un-ticked. This is the most common variant for interactive selection workflows. |
| `remove from list` | Disables (soft-deletes) the list rows whose primary keys match the submitted ids. **The `value.id` field for this variant must be the primary key of the *list table* row** (not the source table row), since this action operates directly on list rows by id. |

---

## Notes

- The `disabled` column uses a soft-delete pattern: records are never physically deleted. A
  disabled record can be re-enabled by selecting the item again.
- `update list` is idempotent: submitting the same set of checked boxes twice produces the same
  result.
- If the source table has a `master_id` column, the row's master is used for access-control
  checks during insertion. If not, set `from_master_id` to `-1` and the list table must have
  `no_master_association` configured.
- The column header in the rendered results table shows a **Select all / Unselect all** toggle
  link automatically. No additional report configuration is required for this.
