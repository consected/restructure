# Layout Name: Navigations

## Top Menu Bar

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

## Additional Master Tabs

Provide additional master tabs that link to pages specific to the currently viewed master record.

    nav:
      label: actions
      links:
        - label: Print Summary
          resource_name: view_dashboards
          resource_type: general
          url: /page_layouts/summary?filters[master_id]={{id}}
