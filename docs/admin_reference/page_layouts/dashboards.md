## Dashboards

A dashboard allows rows and columns of resources, such as reports and charts, to make up a page.

Pages are accessed through links like this: `/page_layouts/[panel name]` by users with user access controls for **view_pages** or **view dashboard**

    ---
    container:
      rows:


        - cols:
            - label: Reference Data Home
              header: |
                The reference data app manages the 
                full study data dictionary, 
                REDCap integrations
                and other app metadata.


              classes: col-md-offset-4  col-md-16
        - cols:
            - label: Study Completers
              classes: col-md-offset-2  col-md-10
              report:
                id: zeus-charts__completers_by_study_charts

            - label: Completers Over Time
              classes: col-md-10
              report:
                id: zeus-charts__study_completers_over_time_chart
                defaults:
                  from_date: 2019-01-01
                  to_date: 2021-12-31

## Passing URL Parameters into Dashboard Content

URL query parameters can be used to dynamically control the content shown by `report:` and `resource:` blocks on a dashboard page.

Parameters are passed using the `filters` namespace:

    /page_layouts/my-dashboard?filters[some_field]=value&filters[master_id]=12345

### Reports

A report block's search criteria can be set or overridden at page-load time via URL `filters` params. Any `filters` key that matches a search attribute declared by the report will be merged into the report's search criteria, with the URL value taking precedence over any static `defaults` specified in the layout config.

Keys that are **not** declared as search attributes by the report are silently ignored — this ensures that arbitrary URL input cannot be injected into the report's SQL query.

    # Static defaults are used as fallback when no matching URL param is supplied:
    report:
      id: my-report
      defaults:
        from_date: 2020-01-01   # used unless ?filters[from_date]=... is in the URL
        to_date: 2020-12-31

    # Access the page with dynamic values:
    # /page_layouts/my-dashboard?filters[from_date]=2024-01-01&filters[to_date]=2024-06-30

### Resources

Resource blocks support the following `filters` URL params to restrict which record is displayed:

| URL param | Description |
|---|---|
| `filters[master_id]` | Show only the master record with this ID |
| `filters[master_type]` | Alternative master record type (used with `find_with` in `view_options`) |
| `filters[resource_id]` | Show only the resource record with this ID |
| `filters[secondary_key]` | Filter by secondary key instead of ID |

    # Example: show a specific master record's activity logs
    # /page_layouts/my-dashboard?filters[master_id]=105634
