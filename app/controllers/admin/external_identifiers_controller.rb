# frozen_string_literal: true

class Admin::ExternalIdentifiersController < AdminController
  helper_method :permitted_params, :objects_instance, :human_name
  before_action :set_defaults
  # after_action :routes_reload, only: %i[update create]

  def schema_reference
    respond_to do |format|
      format.json do
        render json: OptionConfigs::ExternalIdentifierOptions.accepted_config_schema(format: :json),
               content_type: 'application/json'
      end
      format.yaml do
        render plain: OptionConfigs::ExternalIdentifierOptions.accepted_config_schema(format: :yaml),
               content_type: 'application/x-yaml'
      end
    end
  end

  def details
    @external_identifiers = ExternalIdentifier.active.order(label: :asc)
    render 'admin/external_identifier_details/index_admin_external_identifiers'
  end

  protected

  def routes_reload
    DynamicModel.routes_reload
  end

  def default_index_order
    { updated_at: :desc }
  end

  def set_defaults
    @show_again_on_save = true
    @show_extra_help_info = { form_info_partial: 'admin/external_identifiers/form_info' }
  end

  def view_folder
    'admin/common_templates'
  end

  def permitted_params
    @permitted_params = %i[id name label external_id_attribute category alphanumeric
                           external_id_view_formatter external_id_edit_pattern prevent_edit
                           pregenerate_ids min_id max_id extra_fields schema_name disabled
                           options]
  end

  def admin_links(id = nil)
    id = id.id if id.respond_to? :id
    [
      ['details', "/admin/external_identifier_details/#{id}"]
    ]
  end

  def filters
    {
      category: ExternalIdentifier.pluck(:category).uniq.compact,
      name: ExternalIdentifier.pluck(:name).uniq.compact,
      in_current_app_type: %w[yes no]
    }
  end

  def filters_on
    %i[category name in_current_app_type]
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

  def extra_index_columns
    { in_current_app_type_result_checkbox: 'In current app type' }
  end

  def admin_labels
    {
      name: 'Table name'
    }
  end

  def index_params
    permitted_params + %i[admin_id] - %i[disabled options]
  end

  #
  # Override to specify attributes to initialize a definition with
  # @return [Hash]
  def init_new_with_attrs
    initial_attrs_config_for(:default_options_external_identifier)
  end
end
