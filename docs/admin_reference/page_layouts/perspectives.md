# Activity Log Panel Perspectives

**Perspectives** add a row of filter buttons above an activity log content block within a master
panel.  Clicking a button reloads the list server-side with the configured filter applied.
Clicking the **All** button restores the unfiltered list.

Perspectives are configured entirely through the *Page Layout* admin panel — no code changes are
required.

---

## Overview

When perspectives are enabled for a resource inside a panel, the UI renders a `btn-group` bar
directly above the activity log list:

```
[ All ]  [ Recent Active ]  [ My Open ]  [ Closed ]
```

The active button is highlighted.  Clicking any button triggers an AJAX reload of the list using
the perspective's backend (a `where:` filter, a Report, or both with an optional `order:` and
`limit:`).

---

## Configuration

Perspectives are defined inside `view_options` of a **Master Panel** page layout.

### Minimal example — `where:` backend

```yaml
contains:
  resources:
    - activity_log__case_reviews
view_options:
  initial_show: true
  perspectives:
    activity_log__case_reviews:
      - name: recent_active
        label: Recent Active
        where:
          status: active
        order:
          created_at: desc
        limit: 20
      - name: my_closed
        label: My Closed
        where:
          status: closed
      - name: assigned_to_me
        label: Mine
        where:
          assigned_to: '{{current_user_email}}'   # resolved to the logged-in user's email
  default_perspective: recent_active
```

### Example using a Report backend

```yaml
view_options:
  perspectives:
    activity_log__data_requests:
      - name: my_open
        label: My Open
        report:
          resource_name: dr_my_open_report
          defaults:
            status: open
        limit: 50
```

### Example using a Conditional Calculation backend

```yaml
view_options:
  perspectives:
    activity_log__case_reviews:
      - name: active_mine
        label: My Active
        conditional_calculation:
          activity_log__case_reviews:
            status: active
            return: return_all_results
        order:
          created_at: desc
        limit: 25
```

---

## `perspectives` key

The value is a **hash keyed by resource name** (the activity log's resource name, e.g.
`activity_log__case_reviews`).  Each value is an **array of perspective definitions**.

```yaml
perspectives:
  <activity_log_resource_name>:
    - name: <slug>          # (required) identifier used in request params
      label: <text>         # (required) button label shown to the user
      where:                # (optional) AR conditions hash — column names are
        <column>: <value>   #   whitelisted against the model's actual columns.
                            #   String values support {{field_defaults}} substitutions
                            #   evaluated against the current user/master context
                            #   (e.g. current_user_email, current_user).
      report:               # (optional, mutually exclusive with where: and conditional_calculation:)
        resource_name: <alt_resource_name>   # report's alt_resource_name
        defaults:                            # (optional) criteria hash passed
          <key>: <value>                     #   to the report runner;
                                             #   supports {{table_name}} and
                                             #   {{schema_name}} substitutions
      conditional_calculation:  # (optional, mutually exclusive with where: and report:)
        <resource_name>:        # CalcActions condition hash; use field: value for equality,
          <field>: <value>      #   or a condition hash for other operators.
          return: return_all_results  # required return directive
      order:                # (optional) whitelisted sort order
        <column>: asc|desc  #   only valid column names are applied
      limit: <integer>      # (optional) max records returned for this perspective
```

### Perspective definition keys

| Key | Required | Description |
|-----|----------|-------------|
| `name` | ✅ | Slug used in request parameters and in `default_perspective` references.  Use `all` with no backend to create an explicit "All" reset button (one is always added automatically). |
| `label` | ✅ | Button label displayed to the user. |
| `where` | — | Hash of `{ column: value }` conditions applied as an ActiveRecord `where`.  Column names are validated against the model's columns.  String values support `{{field_defaults}}` substitutions evaluated against the current user/master context (e.g. `current_user_email`, `current_user`).  Mutually exclusive with `report` and `conditional_calculation`. |
| `report` | — | Report-based backend.  Specify the report's `alt_resource_name` and optional `defaults` criteria.  Mutually exclusive with `where` and `conditional_calculation`. |
| `conditional_calculation` | — | [ConditionalActions](../../dev_reference/main/architecture_overview.md) condition hash targeting the activity log's own resource name.  Use `field: value` pairs for equality conditions and `return: return_all_results` as the return-mode directive.  `no_masters: {}` is injected automatically.  Mutually exclusive with `where` and `report`. |
| `order` | — | Hash of `{ column: "asc" \| "desc" }`.  Column names are validated against the model's columns.  When omitted, a default ordering is applied automatically (see **Ordering** below). |
| `limit` | — | Integer maximum number of records returned.  Overrides the panel-level `limit` view option for this perspective. |

> **Note:** If none of `where`, `report`, or `conditional_calculation` is provided, clicking the button returns the full
> unfiltered list (equivalent to the built-in **All** button).

---

## Ordering

The ordering applied to a perspective result follows this priority (highest wins):

| Priority | Condition | Ordering applied |
|----------|-----------|------------------|
| 1 | `order:` is present in the perspective config | The specified columns/directions.  Column names are whitelisted; invalid names are silently ignored. |
| 2 | `report:` backend, no `order:` | The row order returned by the report SQL is preserved using `array_position`.  Write `ORDER BY` in your report SQL to control it. |
| 3 | Any other backend, no `order:` | `action_when_attribute DESC, id DESC` — matching the chronological ordering used on the master panel (mirrors the activity log's `Master` has_many scope). |

**`action_when_attribute`** is the field configured on the activity log definition (e.g. `called_when`, `completed_when`).  If it is set to `alt_order`, `created_at` is used instead.

Report perspectives intentionally do **not** fall back to `action_when_attribute` because the report author controls the ordering via the SQL `ORDER BY` clause.  Add an explicit `order:` to override it.

---

## `default_perspective` key

Set at the panel level inside `view_options` to specify which perspective button should be active
when the panel first loads.

```yaml
view_options:
  perspectives:
    activity_log__case_reviews:
      - name: recent_active
        label: Recent Active
        where:
          status: active
  default_perspective: recent_active   # slug of the perspective to activate by default
```

If `default_perspective` is omitted, the **All** button is active by default.

---

## Per-user default via App Configuration

The panel-level `default_perspective` can be overridden on a per-user (or per-role) basis using
the **`default activity log perspective`** `Admin::AppConfiguration` entry.

The configuration value is a YAML hash where each key is an activity log resource name and the
value is the perspective slug to activate:

```yaml
activity_log__case_reviews: recent_active
activity_log__data_requests: my_open
```

Conditional substitutions (evaluated against the current user) are supported:

```yaml
activity_log__case_reviews: |
  {{#is role_name '===' 'coordinator'}}
    coordinator_view
  {{else is role_name '===' 'reviewer'}}
    reviewer_view
  {{/is}}
```

**Precedence** (highest to lowest):

1. `default activity log perspective` app configuration (per user / role)
2. Panel-level `default_perspective` in `view_options`
3. Built-in **All** (no filter)

---

## Complete example

```yaml
contains:
  resources:
    - activity_log__case_reviews
view_options:
  initial_show: true
  limit: 25
  perspectives:
    activity_log__case_reviews:
      - name: recent_active
        label: Recent Active
        where:
          status: active
        order:
          created_at: desc
        limit: 20
      - name: my_closed
        label: My Closed
        where:
          status: closed
      - name: high_priority
        label: High Priority
        report:
          resource_name: case_review_high_priority_report
          defaults:
            schema_name: "{{schema_name}}"
        order:
          priority_rank: asc
        limit: 50
  default_perspective: recent_active
```

---

## HTML structure

The perspectives bar is rendered as a Bootstrap `btn-group` above the activity log list:

```html
<div class="activity-log-perspectives btn-group"
     data-resource="activity_log__case_reviews"
     data-panel-name="my-panel-name">

  <a class="btn btn-default btn-xs activity-log-perspectives__btn active"
     data-perspective=""
     data-remote="true">All</a>

  <a class="btn btn-default btn-xs activity-log-perspectives__btn"
     data-perspective="recent_active"
     data-remote="true">Recent Active</a>

  <!-- … additional perspective buttons … -->
</div>
```

The `active` CSS class is toggled on the clicked button by the JavaScript handler in
`app/assets/javascripts/app/page_layouts.js`.

---

## Notes

- Perspectives only appear when the `perspectives` key is present in `view_options` for the
  resource.  If the key is absent the button bar is not rendered.
- Column names in `where:` and `order:` are whitelisted against the model's actual database
  columns.  Invalid column names are silently ignored.
- When `order:` is omitted, results are ordered by `action_when_attribute DESC, id DESC` for
  `where:`, `conditional_calculation:`, and no-backend perspectives.  For `report:` perspectives,
  the SQL row order from the report is preserved; use `ORDER BY` in the report SQL to control it.
- Access control is respected: if a user does not have access to the underlying Report resource,
  the perspective returns `nil` and the full unfiltered list is shown instead.
- The `conditional_calculation` backend uses `ConditionalActions` with `no_masters: {}` injected
  automatically so the query runs directly against the activity log table (not joined through
  `masters`).  Use `return: return_all_results` as a field-level directive to collect matching
  records.  If the calculation returns no results the full unfiltered list is shown instead.
  Results are always re-scoped through the activity log class and master record to prevent
  cross-resource or cross-master leakage.
- The `limit` on an individual perspective overrides the panel-level `limit` view option only for
  that perspective.
