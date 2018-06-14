class Admin::MessageTemplatesController < AdminController

  helper_method :message_type_options, :template_type_options
  protected

  def view_folder
    'admin/common_templates'
  end

  def filters
    {
      message_type: Admin::MessageTemplate.message_types.map(&:to_s),
      template_type: Admin::MessageTemplate.template_types.map(&:to_s)
    }
  end

    def filters_on
      [:message_type, :template_type]
    end

    def default_index_order
      {name: :asc}
    end

    def template_type_options
      Admin::MessageTemplate.template_types
    end

    def message_type_options
      Admin::MessageTemplate.message_types
    end

  private
    def permitted_params
        [:name, :message_type, :template_type, :template, :disabled]
    end
end
