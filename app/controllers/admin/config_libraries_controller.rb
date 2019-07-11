class Admin::ConfigLibrariesController < AdminController

  helper_method :format_options

  protected

    def view_folder
      'admin/common_templates'
    end

    def default_index_order
      {updated_at: :desc}
    end

    def filters
      {
        category: Admin::ConfigLibrary.active.pluck(:category).uniq.compact,
        format: format_options
      }
    end

    def filters_on
      [:category, :format]
    end

    def format_options
      Admin::ConfigLibrary.valid_formats
    end

  private
    def permitted_params
      [:name, :category, :format, :options, :disabled]
    end

end
