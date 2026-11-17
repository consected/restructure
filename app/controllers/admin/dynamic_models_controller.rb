# frozen_string_literal: true

class Admin::DynamicModelsController < AdminController
  include DefinitionVersionsController

  helper_method :permitted_params, :objects_instance, :human_name,
                :resource_name_column, :batch_jobs_column, :view_sql_column
  before_action :set_defaults
  helper_method :view_folder
  # after_action :routes_reload, only: %i[update create]

  def schema_reference
    respond_to do |format|
      format.json do
        render json: OptionConfigs::DynamicModelOptions.accepted_config_schema(format: :json),
               content_type: 'application/json'
      end
      format.yaml do
        render plain: OptionConfigs::DynamicModelOptions.accepted_config_schema(format: :yaml),
               content_type: 'application/x-yaml'
      end
    end
  end

  def update_config_from_table
    set_instance_from_id
    object_instance.current_admin = current_admin
    object_instance.update_config_from_table
    object_instance.save!
    edit
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
      id: DynamicModel.order(:id).pluck(:id),
      category: DynamicModel.categories,
      table_name: DynamicModel.table_names,
      in_current_app_type: %w[yes no]
    }
  end

  def filters_on
    %i[id category table_name in_current_app_type]
  end

  #
  # Extract the custom in_current_app_type filter value for use by
  # filtered_in_current_app_type. Unlike a previous version of this method, the key is NOT
  # deleted from the returned hash here - doing so also stripped it from the hash the
  # filter dropdown UI reads to show the current selection (filter_select), causing the
  # dropdown to always show "All" even though filtering was working correctly. The key is
  # instead excluded from the database `where` clause via #non_column_filter_keys below.
  # @return [Hash]
  def filter_params
    result = super
    @in_current_app_type_filter = result&.[](:in_current_app_type)
    result
  end

  #
  # Exclude in_current_app_type from the where-clause hash in filtered_primary_model,
  # since it isn't a real database column - see #filter_params above.
  # @return [Array<Symbol>]
  def non_column_filter_keys
    [:in_current_app_type]
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
      batch_jobs_column: 'Batch job?',
      view_sql_column: 'Is a view?',
      in_current_app_type_result_checkbox: 'In current app type'
    }
  end

  #
  # Show a boolean checkbox if the dynamic model has a batch_trigger configured
  # @param [DynamicModel] list_item
  # @return [String] HTML for checked/unchecked indicator
  def batch_jobs_column(list_item)
    return helpers.index_list_item_boolean_field(false) unless list_item.persisted?

    helpers.index_list_item_boolean_field(configuration_key_present?(list_item, :batch_trigger))
  end

  #
  # Show a boolean checkbox if the dynamic model has view_sql configured
  # @param [DynamicModel] list_item
  # @return [String] HTML for checked/unchecked indicator
  def view_sql_column(list_item)
    return helpers.index_list_item_boolean_field(false) unless list_item.persisted?

    helpers.index_list_item_boolean_field(configuration_key_present?(list_item, :view_sql))
  end

  #
  # Quick presence check for a top-level _configurations: key (e.g. batch_trigger, view_sql),
  # scanning just the _configurations: block of the definition's resolved options text
  # (standard defs and config libraries substituted in, but not fully YAML-parsed/merged)
  # rather than running the full option_configs parse for every index row - see issue #1354.
  # Scoping the scan to the _configurations: block (rather than the whole text) avoids false
  # positives from a field or label elsewhere in the config happening to be named
  # batch_trigger/view_sql. This is still an approximation: it does not evaluate
  # _merge_default/_override semantics, so a key could show as present even if a later
  # override removes it.
  # Note: unlike option_configs, this does not suppress the result for disabled definitions,
  # since the raw text scan doesn't depend on the definition being active.
  # @param [DynamicModel] list_item
  # @param [Symbol] key
  # @return [Boolean]
  def configuration_key_present?(list_item, key)
    block = configurations_block_for_scan(list_item)
    block.present? && block.match?(/^\s*#{Regexp.escape(key.to_s)}:/)
  rescue StandardError
    false
  end

  # Matches the indented body of a top-level `_configurations:` YAML section, stopping at
  # the next top-level (non-indented, non-blank) key.
  ConfigurationsBlockRegex = /^_configurations:[ \t]*\n((?:[ \t].*\n?|[ \t]*\n)*)/

  #
  # Extract just the _configurations: block from the resolved options text.
  # @param [DynamicModel] list_item
  # @return [String, nil]
  def configurations_block_for_scan(list_item)
    text = resolved_options_text_for_scan(list_item)
    text&.[](ConfigurationsBlockRegex, 1)
  end

  #
  # Build the resolved options text (standard defs prepended, config libraries substituted)
  # for a quick text scan, without the full YAML parse. Deliberately avoids
  # OptionConfigs::ExtraOptions#prepare_options_text, which resolves
  # `uses_current_definition_version?` internally - that triggers a full option_configs
  # parse just to read one flag, defeating the point of a lightweight scan. Since the admin
  # index always shows the current (not a historical versioned) definition record, libraries
  # can safely be resolved to their current content here.
  # Memoized per list_item since both batch_jobs_column and view_sql_column need it for the
  # same row - without this, the index would resolve the text twice per row.
  # @param [DynamicModel] list_item
  # @return [String, nil]
  def resolved_options_text_for_scan(list_item)
    memo_key = :@resolved_options_text_for_scan
    return list_item.instance_variable_get(memo_key) if list_item.instance_variable_defined?(memo_key)

    provider = list_item.class.options_provider
    config_text = list_item.options_text
    result = if config_text.blank?
               nil
             else
               config_text = config_text.gsub(/^---.*\n/, '')
               config_text = provider.prepend_standard_definitions(config_text)
               provider.include_libraries(config_text)
             end
    list_item.instance_variable_set(memo_key, result)
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
    %i[id category name table_name resource_name admin_id]
  end

  #
  # Override to specify attributes to initialize a definition with
  # @return [Hash]
  def init_new_with_attrs
    initial_attrs_config_for(:default_options_dynamic_model)
  end
end
