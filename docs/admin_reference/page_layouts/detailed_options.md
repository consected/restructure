## Page Layouts - Detailed Options

[Dashboards](#dashboards)

[Content Pages](#content-pages)

### Dashboards

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

### Content Pages

A content page uses an activity log to define all the parts that make up each page. A page is identified using an external ID, to allow meaningful named pages to be used to access content libraries. The **study-info** app provides a good example of how to use content pages.

Pages are accessed through links like this: `/content/page/[panel name]` by users with user access controls for **view_pages** or **view dashboard**

Set up a content page with these options

    ---
    container:
      rows:
        - cols:
            - label: 
              classes: reset-row
              resource: 
                name: activity_log__study_info_part
                limit: 1
                embed_all_references: true

    # If the page layout configuration includes
    # *view_options* then pages are access like
    # /content/page/[library name]/[slug defined in activity log page item]

    view_options:
      find_with: study_info_id

    # Otherwise, access pages as:
    # /content/page/[ext-id-name]/[library name]/[slug defined in activity log page item]
