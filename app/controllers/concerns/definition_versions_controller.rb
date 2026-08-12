# frozen_string_literal: true

# Shared `#versions` admin action and version-diff calculation for controllers
# whose model includes Dynamic::VersionHandler (DynamicModel, ActivityLog,
# Admin::ConfigLibrary). Extracted from 3 duplicated copies - see issue #1343.
module DefinitionVersionsController
  extend ActiveSupport::Concern

  def versions
    set_instance_from_id
    object_instance.current_admin = current_admin
    @version_limit = Dynamic::VersionHandler::MAX_DISPLAYED_VERSIONS
    @total_version_count = object_instance.all_versions_count
    @all_versions = object_instance.all_versions_query(limit: @version_limit)
    @version_diffs = calculate_version_diffs(@all_versions)
    render partial: 'admin/common_templates/def_versions'
  end

  protected

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

      # Compare each attribute
      version.each_key do |key|
        next if %w[id def_version].include?(key.to_s)

        current_val = version[key].to_s.gsub("\r\n", "\n")
        previous_val = next_version[key].to_s.gsub("\r\n", "\n")

        diff_data[:changes][key] = [previous_val, current_val] if current_val != previous_val
      end

      # Skip if only timestamp fields changed
      non_timestamp_changes = diff_data[:changes].keys.reject { |k| %w[updated_at created_at].include?(k.to_s) }
      diffs << diff_data if non_timestamp_changes.present?
    end

    diffs
  end
end
