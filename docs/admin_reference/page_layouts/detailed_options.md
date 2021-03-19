# Page Layouts - Detailed Options

- [Master Panels](#master-panels)
- [Navigations](#navigations)
- [Dashboards](#dashboards)
- [Content Pages](#content-pages)
- [Panel Views](#panel-views)

## Master Panels

**Master Panel** definitions override the default panels available when a master record is viewed.

By default, a master record makes the following panels available:

- Tracker
- Participant Information
- External Identifiers

If a *Master Panel* is defined, the default panels will not be shown, and instead the defined *Master Panel* definitions will be used instead.

*Master Panels* will be displayed in the relative order based on the *Panel position* value.

### Participant Details

A panel containing a column for each of the following:

- Participant Information
- Secondary Participant Information *(unless disabled with the app configuration **hide secondary info** )*
- Addresses
- Contacts *(phone & email)*

Additional dynamic model resources can be added to the **details** category, which will also show alongside the default blocks.

    contains:
      categories:
        - details

### Dynamic Data Models by Category

Show all dynamic model resources with the defined categories

    contains:
      categories: 
        - <category name in dynamic model definitions>
        - ...

### Tracker panel

Show the Tracker panel

    contains:
      categories: 
        - trackers

### Activity Log panel

Show a panel for an activity log definition

    contains: 
      resources:
        - activity_log__ipa_assignments

### External Identifiers

A panel containing all visible *External Identifier* resources

    contains:
      categories: 
        - external-ids

### External Links

A panel showing *External Links* associated with the master record

    contains:
      categories: 
        - external-links

### View Options

The following common view options may be useful:

    view_options:
      initial_show: true                  # Show panel automatically when 
                                          # the master record is opened

      add_item_label: contact             # button label for adding a resource

      orientation: (vertical|horizontal)  # panel orientation for 
                                          # block lists

      limit: (integer)                    # max number of items to show in panel

These view options are used by standalone page layouts:

      initial_show: true|false            # initially open up a panel

      find_with: (msid|scantron_id|...)   # the alternative id 
                                          # (crosswalk or external id) 
                                          # to search for the master record
                                          # with for standalone pages

## Navigations

### Top Menu Bar

Top menu bar navigations can be defined, linking to a resource type (typically a report), or
a URL. Even for the URL definition, a resource name and type are specified, allowing user access
controls to be evaluated to define if the link is shown to a specific user.

    nav:
      # array of links
      links: 
        - label: View Report              # visible label
          url: /reports/test__report      # URL for the nav item
          resource_type: report           # the resource type to use to assess user access to this nav item
          resource_name: test__report     # the resource name to use to assess user access to this nav item

### Additional Master Tabs

Provide additional master tabs that link to pages specific to the currently viewed master record.

    nav:
      label: actions
      links:
        - label: Print Summary
          resource_name: view_dashboards
          resource_type: general
          url: /page_layouts/summary?filters[master_id]={{id}}

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

## Content Pages

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

## Panel Views

A **Panel View** allows configurable styling of a specific panel within a master record.
The panel can also have CSS applied to its content.

    container:
      rows:
        - cols:
            - label: Participant Summary
              header: |
                ## IPA ID: {{ids.ipa_id}}
              
              classes: col-md-24 col-lg-24
              resource: 
                name: activity_log__ipa_assignment_summary
          styles:
            min-height: 10vh
            
    view_css:
      selectors:
        div.sp-col-inner:
          border: 0
          box-shadow: none
        .sp-main:
          margin: 2% 5%
