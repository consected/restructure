# frozen_string_literal: true

# View Redcap project configurations
class Imports::ModelGeneratorsController < AdminController
  include AppTypeChange
  before_action :set_defaults
  helper_method :description_editor

  private

  def set_defaults
    @show_extra_help_info = { form_info_partial: 'imports/model_generators/form_info' }
  end

  def description_editor
    :markdown
  end

  def view_folder
    'admin/common_templates'
  end

  def default_index_order
    { updated_at: :desc }
  end

  def primary_model
    Imports::ModelGenerator
  end

  def permitted_params
    %i[name dynamic_model_table category options description]
  end

  #
  # Just in case the file store has not been set up for this project admin,
  # create it now if necessary
  def setup_file_store
    object_instance.current_admin ||= current_admin
    return if object_instance.file_store

    object_instance.create_file_store
  end
end
