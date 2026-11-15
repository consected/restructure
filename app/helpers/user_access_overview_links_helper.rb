# frozen_string_literal: true

# Helpers for building drill-down links into the User Access Overview admin
# reports. These reports are seeded with a known item_type of
# 'admin-user-access-overview' and stable short_names. The helpers build the
# report URL using the alt_resource_name and forward only the search_attrs
# that are meaningful for the target report.
module UserAccessOverviewLinksHelper
  USER_ACCESS_OVERVIEW_ITEM_TYPE = 'admin-user-access-overview'

  # The short_names map to the corresponding seeded reports.
  USER_ACCESS_OVERVIEW_REPORTS = {
    by_role: 'user_access_overview_by_role',
    by_resource: 'user_access_overview_by_resource',
    resolved: 'user_access_overview_resolved',
    resource_by_role: 'user_access_overview_resource_by_role',
    roles_only: 'user_access_overview_roles_only',
    users_with_role: 'user_access_overview_users_with_role'
  }.freeze

  # Build the report path for one of the User Access Overview perspectives,
  # filtering blank search_attrs so the URL stays compact and links only
  # appear when they carry meaningful filters.
  # @param key [Symbol] one of USER_ACCESS_OVERVIEW_REPORTS keys
  # @param search_attrs [Hash] filter values to pass through as search_attrs[]
  # @return [String]
  def user_access_overview_report_path(key, search_attrs = {})
    short = USER_ACCESS_OVERVIEW_REPORTS.fetch(key)
    alt_resource_name = "admin_user_access_overview__#{short}"
    cleaned = search_attrs.reject { |_, v| v.nil? || v.to_s.strip.empty? }
    report_path(id: alt_resource_name, search_attrs: cleaned)
  end

  # Render a drill-down link to a User Access Overview report. Returns nil
  # when the filter values needed for the link are not meaningful, so the
  # link is suppressed in that case.
  # @param label [String] display text for the link
  # @param key [Symbol] target report key (see USER_ACCESS_OVERVIEW_REPORTS)
  # @param search_attrs [Hash] filter values to forward
  # @param required [Array<Symbol>] keys in search_attrs that must be present
  # @param html_options [Hash] extra link attributes
  def user_access_overview_link(label, key, search_attrs: {}, required: [], **html_options)
    return if required.any? { |k| search_attrs[k].nil? || search_attrs[k].to_s.strip.empty? }

    href = user_access_overview_report_path(key, search_attrs)
    link_to label, href, html_options
  end
end
