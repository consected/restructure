# frozen_string_literal: true

class Admin::DynamicModelsController < AdminController
  helper_method :permitted_params, :objects_instance, :human_name,
                :resource_name_column, :batch_jobs_column, :view_sql_column
  before_action :set_defaults
  helper_method :view_folder
  # after_action :routes_reload, only: %i[update create]

  def update_config_from_table
    set_instance_from_id
    object_instance.current_admin = current_admin
    object_instance.update_config_from_table
    object_instance.save!
    edit
  end

  def versions
    set_instance_from_id
    object_instance.current_admin = current_admin
    @all_versions = object_instance.all_versions_query
    @version_diffs = calculate_version_diffs(@all_versions)
    render partial: 'admin/common_templates/def_versions'
  end

  def run_batch_now
    set_instance_from_id
    object_instance.current_admin = current_admin

    # Ensure configurations is loaded by parsing option_configs
    object_instance.option_configs unless object_instance.configurations

    # Get batch trigger configuration
    bt = object_instance.configurations&.dig(:batch_trigger)

    # Verify batch_trigger is configured
    unless bt.present?
      @error_message = 'Batch trigger not configured for this model'
      render partial: 'admin/dynamic_models/run_batch_now_error'
      return
    end

    limit = bt[:limit]
    user = object_instance.class.user_for_conf_snippet(bt)

    if bt[:user].present? && user.nil?
      raise FphsException, "Batch trigger user '#{bt[:user]}' not found or is not active"
    end

    # Run batch processing immediately (not as a background job)
    # Get the implementation class and ensure its definition cache is up-to-date
    # This is necessary because the implementation class may have a stale definition_id
    # from a previous request (especially in test environments)
    dynamic_def_imp_class = object_instance.implementation_class
    dynamic_def_imp_class.definition_id = object_instance.id
    DynamicModel.definition_cache[object_instance.id] = object_instance

    @processed_ids = dynamic_def_imp_class.trigger_batch_now(limit:, alt_user: user)
    @success_message = "Batch processing completed. Processed #{@processed_ids.length} record(s)."

    render partial: 'admin/dynamic_models/run_batch_now_success'
  rescue StandardError => e
    Rails.logger.error "Batch processing failed for #{object_instance}: #{e.message}"
    Rails.logger.error e.short_string_backtrace
    @error_message = "Batch processing failed: #{e.message}"
    render partial: 'admin/dynamic_models/run_batch_now_error'
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

  def before_send_processor
    'dynamic_models_admin_form'
  end

  def encode_options_fields
    { options: :base64 }
  end

  def routes_reload
    DynamicModel.routes_reload
  end

  def default_index_order
    { updated_at: :desc }
  end

  def set_defaults
    @show_again_on_save = true
    @show_extra_help_info = { form_info_partial: 'admin/dynamic_models/form_info' }
  end

  def filters
    {
      category: DynamicModel.categories,
      table_name: DynamicModel.table_names,
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
  # Show extra index columns for resource name, batch jobs status, view SQL indicator,
  # and whether the dynamic model is in the current app type
  def extra_index_columns
    {
      batch_jobs_column: 'Batch jobs',
      view_sql_column: 'Is a view?',
      in_current_app_type_result_checkbox: 'In current app type'
    }
  end

  #
  # Show the batch jobs status for the dynamic model.
  # If batch_trigger is configured, shows the frequency.
  # @param [DynamicModel] list_item
  # @return [String]
  def batch_jobs_column(list_item)
    return '' unless list_item.persisted?

    # Ensure configurations is loaded
    list_item.option_configs unless list_item.configurations
    bt = list_item.configurations&.dig(:batch_trigger)
    return '' unless bt.present?

    frequency = bt[:frequency]
    frequency.present? ? frequency.to_s : 'configured'
  rescue StandardError
    ''
  end

  #
  # Show a boolean checkbox if the dynamic model has view_sql configured
  # @param [DynamicModel] list_item
  # @return [String] HTML for checked/unchecked indicator
  def view_sql_column(list_item)
    return helpers.index_list_item_boolean_field(false) unless list_item.persisted?

    # Ensure configurations is loaded
    list_item.option_configs unless list_item.configurations
    has_view_sql = list_item.configurations&.dig(:view_sql).present?
    helpers.index_list_item_boolean_field(has_view_sql)
  rescue StandardError
    helpers.index_list_item_boolean_field(false)
  end

  def view_folder
    'admin/common_templates'
  end

  def permitted_params
    @permitted_params = %i[id name table_name schema_name category
                           table_key_name primary_key_name
                           foreign_key_name result_order field_list position options
                           description disabled]
  end

  def index_params
    %i[id category name table_name resource_name position admin_id]
  end

  #
  # Override to specify attributes to initialize a definition with
  # @return [Hash]
  def init_new_with_attrs
    initial_attrs_config_for(:default_options_dynamic_model)
  end
end
