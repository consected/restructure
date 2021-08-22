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
