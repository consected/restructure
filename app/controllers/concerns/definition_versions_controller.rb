# frozen_string_literal: true

# Shared `#versions` admin action and version-diff calculation for controllers
# whose model includes Dynamic::VersionHandler (DynamicModel, ActivityLog,
# Admin::ConfigLibrary). Extracted from 3 duplicated copies - see issue #1343.
module DefinitionVersionsController
  extend ActiveSupport::Concern

  # Route helper and target container id (see the resource-specific
  # `_versions_panel.html.erb` partials) for each controller this concern is
  # included in - used to build the "load more" pagination link generically
  # from the shared admin/common_templates/_def_versions partial.
  VERSIONS_PANEL_CONFIG = {
    'admin/dynamic_models' => { route_helper: :versions_admin_dynamic_model_path,
                                container_id: 'embedded-dynamic-def-versions-embedded' },
    'admin/activity_logs' => { route_helper: :versions_admin_activity_log_path,
                               container_id: 'embedded-dynamic-def-versions-embedded' },
    'admin/config_libraries' => { route_helper: :versions_admin_config_library_path,
                                  container_id: 'embedded-config-library-def-versions-embedded' }
  }.freeze

  def versions
    set_instance_from_id
    object_instance.current_admin = current_admin
    @current_page = version_panel_page
    @version_limit = Dynamic::VersionHandler::MAX_DISPLAYED_VERSIONS * @current_page
    @total_version_count = object_instance.all_versions_count
    @all_versions = object_instance.all_versions_query(limit: @version_limit)
    @version_diffs = calculate_version_diffs(@all_versions)
    @versions_container_id = versions_panel_config[:container_id]
    @next_versions_page_path = next_versions_page_path
    render partial: 'admin/common_templates/def_versions'
  end

  protected

  # The requested page (1-based) of the versions panel. Each page increases
  # the cumulative fetch limit by MAX_DISPLAYED_VERSIONS, so re-fetching from
  # scratch each time - simpler and always diffs consecutive versions
  # correctly, at the cost of re-querying already-seen rows on each "load more"
  # click (acceptable: it's an explicit, admin-initiated action).
  def version_panel_page
    page = params[:page].to_i
    [page, 1].max
  end

  def versions_panel_config
    VERSIONS_PANEL_CONFIG[params[:controller]] || {}
  end

  # Path to fetch the next page of versions, or nil if every version is
  # already loaded (or this controller isn't in VERSIONS_PANEL_CONFIG).
  def next_versions_page_path
    route_helper = versions_panel_config[:route_helper]
    return nil unless route_helper && @total_version_count > @version_limit

    public_send(route_helper, view_as: 'simple-embedded', readonly: true,
                              id: object_instance.id, page: @current_page + 1)
  end

  def calculate_version_diffs(all_versions)
    return [] if all_versions.blank?

    diffs = []
    all_versions.each_with_index do |version, idx|
      next_version = all_versions[idx + 1]
      next unless next_version

      # Compare this version with the next (older) version
      diff_data = {
        current: version,
        previous: next_version,
        changes: {}
      }

      # Compare each attribute. created_at/updated_at are excluded - they're
      # already shown as standard fields in the header row for each version,
      # so there's no need to duplicate them as a diffed field here.
      version.each_key do |key|
        next if %w[id def_version created_at updated_at].include?(key.to_s)

        current_val = version[key].to_s.gsub("\r\n", "\n")
        previous_val = next_version[key].to_s.gsub("\r\n", "\n")

        diff_data[:changes][key] = [previous_val, current_val] if current_val != previous_val
      end

      diffs << diff_data if diff_data[:changes].present?
    end

    diffs
  end
end
