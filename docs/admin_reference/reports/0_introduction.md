# Reports

## Introduction

**Reports** provide configuration for reporting, search, charts and CSV export. Reports are defined as regular PostgreSQL SQL,
and are run within a transaction that is always rolled-back, to avoid any changes being made to the database, to mitigate
the risk of SQL injection.

Administration is provided in [Admin: Reports](/admin/reports)

## Full Text Search in Reports

Reports can query full-text indexed data by joining to `tsvector` target tables and using PostgreSQL search operators such as `@@`, `to_tsquery`, and `plainto_tsquery`.

See [Full Text Search](full_text_search.md) for a concise guide and query patterns.

## Field Definitions

!defs(report_field_defs.yaml)

## Contents

- [SQL Search Attributes](search_attributes.md)
- [URL Search Attributes](url_search_attributes.md)
- [Detailed Options](detailed_options.md)
- [File Filtering](file_filtering.md)
- [Select Items: Checkbox Actions](select_items_lists.md)
- [Full Text Search](full_text_search.md)
- [Chart Reports](chart_reports.md)
