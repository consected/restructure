# frozen_string_literal: true

class Admin::ActivityLogsController < AdminController
  before_action :set_defaults
  # after_action :routes_reload, only: %i[update create]

  def versions
    set_instance_from_id
    object_instance.current_admin = current_admin
    @all_versions = object_instance.all_versions_query
    @version_diffs = calculate_version_diffs(@all_versions)
    render partial: 'admin/common_templates/def_versions'
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

      # Compare each attribute
      version.keys.each do |key|
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

  protected

  def routes_reload
    DynamicModel.routes_reload
  end

  def default_index_order
    { updated_at: :desc }
  end

  def filters
    {
      category: ActivityLog.pluck(:category).uniq.compact,
      table_name: ActivityLog.active.pluck(:table_name).uniq
    }
  end

  def filters_on
    %i[category table_name]
  end

  def set_defaults
    @show_again_on_save = true
  end

  private

  def permitted_params
    %i[name item_type rec_type process_name category action_when_attribute field_list blank_log_field_list
       disabled hide_item_list_panel extra_log_types main_log_name blank_log_name schema_name]
  end

  def index_params
    %i[name item_type rec_type process_name category schema_name action_when_attribute
       hide_item_list_panel admin_id]
  end

  #
  # Override to specify attributes to initialize a definition with
  # @return [Hash]
  def init_new_with_attrs
    initial_attrs_config_for(:default_options_activity_log)
  end
end
