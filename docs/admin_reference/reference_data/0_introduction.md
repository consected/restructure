# Reference Data Tables

## Introduction

The **Tables** tab of [Reference Data](/admin/reference_data) lists the tables, views and materialized views in the database schemas the app can see. It is available to administrators, and to users with the `view_data_reference` general access control.

## Finding a table or view

- Choose a schema to list its tables and views. History tables are hidden unless *filter out history tables* is unchecked.
- Type in the search field to find a name in any schema. The suggestions show the schema, and whether each match is a table, a view or a *materialized view*. Only the first 50 matches are listed, so keep typing to narrow the results.
- When a single match is found it is selected, expanded and shown on its own. If nothing matches, a message says so.

## Details

Expanding a table or view lists its columns, with their types, comments and foreign keys.

- **view definition** shows the SQL of a view or materialized view, read-only. Anyone allowed to use the Tables tab can read it.
- The magnifier icon opens a search of the table data, when the user has access to the *reference_data__table_data* report.
- The cog icon opens the dynamic model, activity log or external identifier definition that uses the table or view, ready to edit.

## Definition pages

The same details are shown in the **Table / View** tab when editing a dynamic model, activity log or external identifier.
