# Support the display of page layouts and panels
module PageLayoutsHelper
  #
  # Get an ordered list of page layout panels for the named layout
  # in the current user's app, or for any panels where the app type is NULL.
  # The definitions matching the current app always appear first, allowing them to override
  # app-types that are not set.
  # @param [String] layout_name - defaults to 'master' for master record related panels
  # @return [ActiveRecord::Relation]
  def page_layout_panels(layout_name: 'master')
    Admin::PageLayout
      .active
      .where(app_type_id: [nil, current_user.app_type_id], layout_name: layout_name)
      .order(Arel.sql('app_type_id ASC NULLS LAST, panel_position ASC'))
  end

  #
  # Get the first matching panel in the named layout, optionally with a specified
  # panel name and where the categories optionally includes the category
  # @param [String] panel_name - optional panel name to search for
  # @param [String] category - optional category included in :categories option
  # @param [String] layout_name - defaults to 'master' for master record related panels
  # @return [Admin::PageLayout | nil] single page layout definition or nil if not matched
  def page_layout_panel(panel_name: nil, category: nil, layout_name: 'master')
    res = page_layout_panels(layout_name: layout_name)
    res = res.where(panel_name: panel_name) if panel_name
    res = res.select { |r| r.contains&.categories&.include?(category) } if category

    res.first
  end
end
