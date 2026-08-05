# frozen_string_literal: true

class Admin::ActivityLogsController < AdminController
  before_action :set_defaults
  # after_action :routes_reload, only: %i[update create]

  def schema_reference
    respond_to do |format|
      format.json do
        render json: OptionConfigs::ActivityLogOptions.accepted_config_schema(format: :json),
               content_type: 'application/json'
      end
      format.yaml do
        render plain: OptionConfigs::ActivityLogOptions.accepted_config_schema(format: :yaml),
               content_type: 'application/x-yaml'
      end
    end
  end

  def versions
    set_instance_from_id
    object_instance.current_admin = current_admin
    @all_versions = object_instance.all_versions_query
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

  def routes_reload
    DynamicModel.routes_reload
  end

  def default_index_order
    { updated_at: :desc }
  end

  def filters
    {
      category: ActivityLog.pluck(:category).uniq.compact,
      table_name: ActivityLog.active.pluck(:table_name).uniq,
      in_current_app_type: %w[yes no]
    }
  end

  def filters_on
    %i[category table_name in_current_app_type]
  end

  #
  # Override filter_params to extract the custom in_current_app_type filter
  # before the parent class processes it as a database column
  # @return [Hash]
  def filter_params
    result = super
    @in_current_app_type_filter = result&.delete(:in_current_app_type)
    result
  end

  #
  # Override to handle the special "in_current_app_type" filter
  # This filter shows/hides items based on whether they're in the admin's current app type
  # @return [ActiveRecord::Relation]
  def filtered_primary_model(pm = nil)
    pm = super

    filtered_in_current_app_type(pm)
  end

  #
  # Show extra index column indicating if the activity log is in the current app type
  def extra_index_columns
    { in_current_app_type_result_checkbox: 'In current app type' }
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
