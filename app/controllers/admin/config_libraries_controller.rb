# frozen_string_literal: true

class Admin::ConfigLibrariesController < AdminController
  helper_method :format_options
  before_action :set_defaults

  protected

  def set_defaults
    @show_again_on_save = true
    @show_extra_help_info = { form_info_partial: 'admin/config_libraries/form_info' }
  end

  def view_folder
    'admin/common_templates'
  end

  def default_index_order
    { updated_at: :desc }
  end

  def filters
    {
      category: Admin::ConfigLibrary.active.pluck(:category).uniq.compact,
      format: format_options
    }
  end

  def filters_on
    %i[category format]
  end

  def format_options
    Admin::ConfigLibrary.valid_formats
  end

  private

  def permitted_params
    %i[name category format options disabled]
  end
end
