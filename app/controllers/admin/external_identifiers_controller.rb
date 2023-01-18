# frozen_string_literal: true

class Admin::ExternalIdentifiersController < AdminController
  helper_method :permitted_params, :objects_instance, :human_name, :admin_links
  before_action :set_defaults
  after_action :routes_reload, only: %i[update create]

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
    [
      ['details', "/admin/external_identifier_details/#{id}"]
    ]
  end

  def filters
    {
      category: ExternalIdentifier.pluck(:category).uniq.compact,
      name: ExternalIdentifier.pluck(:name).uniq.compact
    }
  end

  def filters_on
    %i[category name]
  end

  def admin_labels
    {
      name: 'Table name'
    }
  end
end
