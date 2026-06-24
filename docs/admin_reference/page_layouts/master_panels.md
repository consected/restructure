# Master Panels

**Master Panel** definitions override the default panels available when a master record is viewed.

By default, a master record makes the following panels available:

- Tracker
- Participant Information
- External Identifiers

If a *Master Panel* is defined, the default panels will not be shown, and instead the defined *Master Panel* definitions will be used instead.

*Master Panels* will be displayed in the relative order based on the *Panel position* value.

## Participant Details

A panel containing a column for each of the following:

- Participant Information
- Secondary Participant Information *(unless disabled with the app configuration **hide secondary info** )*
- Addresses
- Contacts *(phone & email)*

Additional dynamic model resources can be added to the **details** category, which will also show alongside the default blocks.

    contains:
      categories:
        - details

## Dynamic Data Models by Category

Show all dynamic model resources with the defined categories

    contains:
      categories: 
        - <category name in dynamic model definitions>
        - ...

## Tracker panel

Show the Tracker panel

    contains:
      categories: 
        - trackers

## Activity Log panel

Show a panel for an activity log definition

    contains: 
      resources:
        - activity_log__ipa_assignments

## External Identifiers

A panel containing all visible *External Identifier* resources

    contains:
      categories: 
        - external-ids

## External Links

A panel showing *External Links* associated with the master record

    contains:
      categories: 
        - external-links

## View Options

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

## Linking to Expand Tabs

You can create HTML links within your configuration (such as in `caption_before` texts) that automatically expand specific panels when clicked. This is useful for guiding users to the next steps in a workflow within the same master record.

To do this, use a URL hash formatted with `#click-target-[tab-id]`.

- **For standard Activity Log tabs:**
  Use `#click-target-tab-activity-log--[item-type]` where the item type is singular.
  *(Example: `[Open Data Requests](#click-target-tab-activity-log--data-request)`)*

- **For configured `contains.resources` panels (including multi-resource panels):**
  Use `#click-target-tab-resources-[panel-name]` where the panel name is hyphenated with spaces replaced by hyphens.
  *(Example: for a panel named "My Custom Panel", use `[Open Custom Panel](#click-target-tab-resources-my-custom-panel)`)*
  
*Note: For `contains.resources` panels containing only a single resource, the older `#click-target-tab-[resource-name-hyphenated]` format acts as an alias (e.g. `#click-target-tab-activity-log--case-reviews`), but the `tab-resources-[panel-name]` format is preferred.*

## Activity Log Perspectives

Filter buttons can be added above an activity log content block to let users switch between
server-side filtered views of the list.

See [perspectives.md](perspectives.md) for the full configuration reference.
