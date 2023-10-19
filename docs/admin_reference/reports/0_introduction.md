# Reports

## Introduction

**Reports** provide configuration for reporting, search, charts and CSV export. Reports are defined as regular PostgreSQL SQL,
and are run within a transaction that is always rolled-back, to avoid any changes being made to the database, to mitigate
the risk of SQL injection.

Administration is provided in [Admin: Reports](/admin/reports)

## Contents

- [SQL Search Attributes](search_attributes.md)
- [Detailed Options](detailed_options.md)
- [File Filtering](file_filtering.md)
