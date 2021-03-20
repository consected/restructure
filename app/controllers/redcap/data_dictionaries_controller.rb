# frozen_string_literal: true

# View Redcap project configurations
class Redcap::DataDictionariesController < AdminController
  before_action :set_defaults

  helper_method :transfer_mode_options, :notes_editor

  private

  def set_defaults
    @show_extra_help_info = { form_info_partial: 'redcap/data_dictionaries/form_info' }
  end

  def index_params
    %i[redcap_project_admin_name updated_at]
  end

  def notes_editor
    :markdown
  end

  def view_folder
    'admin/common_templates'
  end

  def default_index_order
    { updated_at: :desc }
  end

  def primary_model
    Redcap::DataDictionary
  end

  def permitted_params
    %i[]
  end
end
