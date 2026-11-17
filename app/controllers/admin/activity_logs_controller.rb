# frozen_string_literal: true

class Admin::ActivityLogsController < AdminController
  include DefinitionVersionsController

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
      table_name: ActivityLog.active.pluck(:table_name).uniq,
      in_current_app_type: %w[yes no]
    }
  end

  def filters_on
    %i[category table_name in_current_app_type]
  end

  #
  # Extract the custom in_current_app_type filter value for use by
  # filtered_in_current_app_type. The key is NOT deleted from the returned hash here -
  # doing so also stripped it from the hash the filter dropdown UI reads to show the
  # current selection (filter_select), causing the dropdown to always show "All" even
  # though filtering was working correctly. The key is instead excluded from the database
  # `where` clause via #non_column_filter_keys below.
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
