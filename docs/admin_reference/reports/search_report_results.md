# Search another report from a result cell

A report table can link a result cell to a second report, passing the cell's
value as one of the target report's search attributes. Use a special column
name for a direct master-record search, or configure an ordinary column as a
URL to open an embedded report with its criteria form and results.

## Configure the target report

The target report must declare the search attribute and use its named SQL bind.
For example, this `search_attrs` configuration declares a single numeric
attribute named `player_id`:

```yaml
player_id:
  number:
    multiple: single
```

The target SQL must use `:player_id` and return a `master_id` column so the
application can display matching master records. This example uses the
`player_id` value to find the corresponding player record:

```sql
SELECT pi.master_id, pi.id AS player_id, pi.first_name, pi.last_name
FROM ml_app.player_infos AS pi
WHERE pi.id = :player_id;
```

The report's numeric database ID is used to identify it in the source column
name. In the example below, `12` is the target report's ID; replace it with the
actual ID shown for your target report in the administration interface.

## Special column names: direct master-record search

Return a table result column named
`search_reports_<target_report_id>_<search_attribute>`. Its value becomes the
target search attribute. For example, this source SQL supplies each player's
ID to report `12` as the `player_id` attribute:

```sql
SELECT
  pi.master_id,
  pi.first_name,
  pi.last_name,
  pi.id AS "search_reports_12_player_id"
FROM ml_app.player_infos AS pi;
```

When a user activates the value in that result cell, the application requests
the target report with `commit=search` and displays the returned master results
in a modal titled "Search results for <cell-value>". For report `12` and
attribute `player_id`, the request is
`/reports/12.json?search_attrs[player_id]=<cell-value>&commit=search`. This is a
direct search: the modal does not show the target report's criteria form or
report buttons.

The numeric ID immediately after `search_reports_` identifies the target
report. Everything after the next underscore is the search-attribute name,
including any further underscores. For example,
`search_reports_12_player_record_id` passes `search_attrs[player_record_id]`.
No `column_options.show_as` setting is needed for these special columns.

## Ordinary URL columns: embedded reports and master-record lists

An ordinary column can return a Markdown link and use `column_options.show_as`
to display it as a URL. Append `#open-embedded-report` to the link to open it in
a modal instead of the default new tab. The column can have any name; it does
not need the `search_reports_` prefix.

For example, this source report returns a link labelled "View player":

```sql
SELECT
  pi.first_name,
  pi.last_name,
  '[View player](/reports/12' || chr(63) || 'search_attrs[player_id]=' ||
    pi.id::text ||
    '&search_attrs[no_run]=true#open-embedded-report)' AS player_link
FROM ml_app.player_infos AS pi;
```

Configure the source report's *Options*:

```yaml
column_options:
  show_as:
    player_link: url
```

The SQL uses `chr(63)` to generate `?`, so the report's SQL parameter handling
does not mistake the URL's question mark for a positional bind.

The link handler adds `embed=true` and loads the target report's HTML criteria
form into a modal. `search_attrs[no_run]=true` prevents the initial request from
running the query; the supplied `player_id` appears in the criteria form.
The user can then run the report inside the modal:

- With target *Report type* **regular_report**, the modal's **list** button
  returns the normal report results (typically a table). This button submits
  `commit=table`; its label does not mean a master-record list.
- With target *Report type* **search**, the **search** button returns a
  master-record list. The target SQL must return `master_id`.

To run the target automatically when the modal opens, add `force_run=true`
before the fragment:

```text
/reports/12?search_attrs[player_id]=123&search_attrs[no_run]=true&force_run=true#open-embedded-report
```

For a **search** target, this opens the criteria form and immediately runs the
master-record search. For a **regular_report** target, it runs the normal report.
Unlike the special-column direct search, this route uses the target's
embedded report form, report type, and button configuration. Hidden criteria
or buttons therefore affect its UI.

Use the HTML report URL (without `.json`) with `#open-embedded-report`; the
fragment sets up an HTML embedded-report modal, not the JSON master-results
template used by special column names. Search attributes can contain
underscores in either approach. When constructing URL values, URL-encode
anything that is not a URL-safe scalar; the numeric ID in this example needs
no encoding.

## Constraints and access

- The target report must declare the named search attribute and use it in its
  SQL. For master-record results, it must also return `master_id`; an ordinary
  embedded report table does not require that column.
- For a non-admin user, both link types require read access to the target report
  (or all reports). A special-column direct search additionally requires either
  a target marked *Searchable* or general `view_reports` or `view_report_not_list`
  access. An ordinary URL-column embedded report requires that general access
  even if the target is searchable, because its initial HTML request loads a
  report form. Searchability does not replace report read access.
  Administrators can access reports through the admin authorization path.
- The special-column link works independently of the target report type and its normal report
  and search-button visibility options. It issues a separate
  `commit=search` request, so changing the button options discussed in
  [issue #1522](https://github.com/consected/restructure/issues/1522) does not
  enable or disable this result-cell link. The modal does not show the target
  report's criteria form or report buttons.
- The special-column handler reads the result cell's rendered HTML and inserts it into the
  target URL without URL-encoding it. Use a plain, URL-safe scalar such as a
  numeric ID in the special result column; do not rely on URL formatting or
  HTML-rendered links being converted into a search value.

For an editable source report, `search_reports_...` names listed in *Edit
fields* are excluded from the fields that can actually be updated. The link
handler is driven by the rendered result column name and value; the column
does not need to be an editable database field.
