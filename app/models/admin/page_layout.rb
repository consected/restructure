# frozen_string_literal: true

# Define page, panel and navigation layouts for standard master results panels, standalone pages (dashboards),
# content pages, top nav (menu bar) navigation, master results tab navigation, and custom view panels
class Admin::PageLayout < Admin::AdminBase
  self.table_name = 'page_layouts'

  def self.app_type_not_required
    true
  end

  include AdminHandler
  include AppTyped
  include OptionsHandler
  include PositionHandler

  validates :layout_name, presence: { scope: :active, message: "can't be blank" }
  validates :panel_name, presence: { scope: :active, message: "can't be blank" },
                         uniqueness: { scope: %i[app_type_id layout_name], message: "can't be already present" }
  validates :panel_label, presence: { scope: :active, message: "can't be blank" }

  # @attr [String] layout_name - the role of the definition
  #   - master - a standard master result panel, laid out according to
  #              standard activity log / dynamic model panel configurations, or forced orientation
  #   - user_profile - definition of the panels to show in a user profile page
  #   - nav - top nav (menu bar) item or "master-tabs" item
  #   - standalone - a standalone page / dashboard
  #   - view - a panel that allows row / column layout definition

  # @attr [String] panel_name - a distinct name for a panel or panel
  #   In the case of 'nav' layout, 'master-tabs' specifies specific tabs to add to the master tab panel
  #   in addition to those added for access to panels.

  # @attr [String] panel_label - the visible panel name or page name in lists

  # @attr [Integer | null] panel_position - the relative position a panel will appear in

  #
  # Option configurations are defined as YAML documents with the following structures
  # ===

  # The :contains definition is used within standalone page or panel definitions to
  # specify where the page or panel gets its content from.
  # The options are categories or resources structures
  #
  # contains:
  #   categories: named activity log, dynamic model or special categories
  #     Special categories are:
  #        - 'details' - standard subject panel including  subject info, secondary info, addresses and subject contacts
  #                      plus any other dynamic models in the 'dynamic' category
  #        - 'trackers' - the trackers panel
  #        - 'external-ids' - all available external identifiers
  #        - 'external-links' - defined external links for a master record
  #   resources: a single or array of named resources (model names)
  configure :contains, with: %i[categories resources]

  # Which master record tab should this panel appear under if we are in a master-tabs definition
  # tab:
  #   parent: allows for this tab to appear as a drop down under this parent tab
  configure :tab, with: [:parent]

  # View options for the panel or standalone page
  # view_options:
  #   add_item_label: button label for adding a resource
  #   orientation: panel orientation (vertical|horizontal)
  #   limit: max number of items to show in panel
  #   initial_show: initially open up a panel
  #   find_with: the alternative id (crosswalk or external id) to search for the master record with for standalone pages
  configure :view_options,
            with: %i[initial_show orientation add_item_label limit find_with hide_sublist_controls default_expander
                     hide_activity_logs_header close_others
                     show_for_single_master_only show_for_multi_master_only filter_items]

  # List options for dashboards list
  configure :list_options, with: %i[hide_in_list]

  # Add a navigation (top menu bar) item as either a link or a list of resources (reports typically)
  # links: array of links
  #    - label: visible label
  #      url: URL for the nav item
  #      resource_type: the resource type to use to assess user access to this nav item
  #      resource_name: the resource name to use to assess user access to this nav item
  #      resource_app_type: optionally test resource access against this app rather than the current one
  #                         allowing general / app_type / app type name to test if a user can access another app
  # resources: (unknown)
  # label: (unknown)
  configure :nav, with: %i[links resources label]

  # A standalone page container defining rows that define the contents of the page
  # container:
  #   rows: an array of row definitions
  #     classes: string of space separated class names to add directly to each standard-page-row div
  #     styles: maps key: value to standard styles
  #     cols:
  #       label: top title label (with {{substitutions}})
  #       header: header markdown block (with {{substitutions}})
  #       footer: footer markdown block (with {{substitutions}})
  #       classes: string of space separated class names to add to the column div
  #       id: optional DOM id (a prefix of 'sp-col-' is added), defaults to id underscored label value
  #       inner_rows:
  #         rows: uses definition 'cols'
  # One of the following may be used
  #       url: static URL to pull from
  #       report:
  #         id: report id / resource name
  #         defaults: hash defining the attribute: value pairs to pass as report criteria
  #       resource:
  #         name: resource name
  #         id: optional resource id to filter the results on
  #               if missing, the URL params filters[resource_id] will be used (if present)
  #         secondary_key: optional secondary key to filter the results on
  #               if missing, the URL params filters[secondary_key] will be used (if present)
  #         limit: max items in results
  #         embed_all_references: show resource blocks in results with embedded items fully populated
  #
  #  options: (unknown)
  configure :container, with: %i[rows options]

  # Define CSS to be applied to this panel or page block
  # All definitions are prefixed with the block id, to ensure they don't leak to other parts of the page
  # view_css:
  #   classes:
  #     class-name:
  #       display: block
  #       margin-right: 20px
  #   selectors:
  #     "#an-id .some-class":
  #       display: block
  #       margin-right: 20px
  configure :view_css, with: %i[classes selectors media_queries]

  scope :standalone, -> { where layout_name: 'standalone' }
  scope :view, -> { where layout_name: 'view' }
  scope :showable, -> { where layout_name: %w[view standalone] }

  def to_s
    "#{layout_name}: #{panel_label}"
  end

  def config_text
    options
  end

  def config_text=(value)
    self.options = value
  end

  def self.no_master_association
    true
  end

  #
  # Get dashboards that the user has access to in its current app
  # @param [User] user
  # @return [ActiveRecord::Relation] standalone page layouts
  def self.standalone_pages_for_user(user)
    if user.has_access_to?(:read, :standalone_page, :_all_standalone_pages_)
      all
    else
      ns = []
      all.each do |r|
        ns << r.id if standalone_page_available_to_user r, user
      end

      where(id: ns)
    end
  end

  #
  # Does the user have access to show the standalone page?
  # @param [Report] report
  # @param [User] user
  # @return [Boolean]
  def self.standalone_page_available_to_user(page, user)
    user.has_access_to?(:read, :standalone_page, page.panel_name)
  end

  #
  # Active standalone layouts for the specified app type
  # @return [ActiveRecord::Relation] standalone page layouts
  def self.app_standalone_layouts(app_type_id)
    Admin::PageLayout.active.standalone.where(app_type_id:)
  end

  #
  # Active view or standalone layouts for the specified app type
  # @return [ActiveRecord::Relation] all active layout types for app
  def self.app_show_layouts(app_type_id)
    Admin::PageLayout.active.showable.where(app_type_id:)
  end

  def self.position_attribute
    :panel_position
  end

  def position_group
    { app_type_id:, layout_name: }
  end

  def standalone?
    layout_name == 'standalone'
  end

  #
  # Equivalent to `HandlesUserBase#can_access?`
  # A user can access a page layout if it is included as a named
  # resource, or if _all_standalone_pages_ is specified
  def can_access?(user)
    return true if self.class.standalone_page_available_to_user self, user

    user.has_access_to?(:read, :standalone_page, :_all_standalone_pages_)
  end

  # Provide a viewable name
  def name
    "#{layout_name} #{panel_name}"
  end
end
