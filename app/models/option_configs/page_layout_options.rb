module OptionConfigs
  class PageLayoutOptions < BaseOptions
    def self.raise_bad_configs(_option_configs)
      # None defined - override with real checks
      # @todo
    end

    def self.attr_defs
      <<~END_YAML
        #
        # The :contains definition is used within standalone page or panel definitions to
        # specify where the page or panel gets its content from.
        # The options are categories or resources structures
        #
        contains:
          categories:
            # named activity log, dynamic model or "special categories"
            # Special categories are:
            - details     # standard subject panel including
                          # subject info, secondary info, addresses and subject contacts
                          # plus any other dynamic models in the 'dynamic' category
            - trackers    # the trackers panel
            - external-ids    # all available external identifiers
            - external-links  # defined external links for a master record
          resources:
            # a single or array of named resources (model names)
            - activity_log__player_contact_phones
        #
        # View options for the panel or standalone page
        view_options:
          add_item_label: contact             # button label for adding a resource
          orientation: (vertical|horizontal)  # panel orientation for block lists
          limit: (integer)                    # max number of items to show in panel
          initial_show: true|false            # initially open up a panel
          find_with: (msid|scantron_id|...)   # the alternative id (crosswalk or external id)
                                              # to search for the master record with for standalone pages
        #
        # Add a navigation (top menu bar) item as either a link or a list of resources
        # Providing a resource name and type allows user access controls to be enforced
        # NOTE: to add the nav to the top page menu, specify panel name 'page' (or 'all').
        #       To add the nav to a master result, use panel name 'master-tabs'
        nav:
          # array of links
          links:
            - label: View Report              # visible label
              url: /reports/test__report      # URL for the nav item
              resource_type: report           # the resource type to use to assess user access to this nav item
              resource_name: test__report     # the resource name to use to assess user access to this nav item
        #
        # Add a master record tab for a Panel Name "master-tabs"
            - label: Print Summary
              resource_name: view_dashboards
              resource_type: general
              url: /page_layouts/summary?filters[master_id]={{id}}
        #
        # Which master record tab should this panel appear under if we are in a
        # nav "master-tabs" definition
        #
        tab:
          parent: allows for this tab to appear as a drop down under this parent tab
        #
        # A standalone page container defining rows that define the contents of the page
        container:
          rows: an array of row definitions
            classes: string of space separated class names to add directly to each standard-page-row div
            styles: maps key: value to standard styles
            cols: &cols
              label: "Top Heading {{id}}"      # top title label (with {{substitutions}})
              header: "Some *details*..."      # header markdown block (with {{substitutions}})
              footer: "Footer *details*..."    # footer markdown block (with {{substitutions}})
              classes: class-1 class-2         # string of space separated class names to add to the column div
              id: special-dom-id               # optional DOM id (a prefix of 'sp-col-' is added),
                                                # defaults to id underscored label value
              inner_rows:
                rows:
                  # uses *cols for each row within this column
              #
              # To define what is displayed in a cell
              # one of the following may be used - url:, report: or resource:
              url: static URL to pull from

              #
              #
              report:
                # View a report (table, chart, etc) with default values
                id: test__report          # report id / resource name

                defaults:
                  # hash defining the attribute: value pairs to pass as report criteria
                  age: 40
                  status: married
              #
              #
              resource:
                # View a resource list (such as activity logs)
                name: activity_log__player_contact_phone        # resource name
                id: 123     # optional resource id to filter the results on
                            # if missing, the URL params
                            # *filters[resource_id]* will be used (if present)
                secondary_key: scantron_id      # optional secondary key to filter the results on
                                                # if missing, the URL params
                                                # *filters[secondary_key]* will be used (if present)
                limit: 1    # max items in results
                embed_all_references: show resource blocks in results with embedded items fully populated
          #
          options: (unknown)
        #
        #
        # Define CSS to be applied to this panel or page block
        # All definitions are prefixed with the block id, to ensure they don't leak to other parts of the page
        #
        view_css:
          classes:
            class-name:
              display: block
              margin-right: 20px
          selectors:
            "#an-id .some-class":
              display: block
              margin-right: 20px
      END_YAML
    end
  end
end
