class Admin::MessageTemplatesController < AdminController

  protected
  def filters
    {
      message_type: ['email'],
      template_type: ['layout', 'content']
    }
  end

    def filters_on
      [:message_type, :template_type]
    end

    def default_index_order
      {name: :asc}
    end

  private
    def permitted_params
        [:name, :message_type, :template_type, :template, :disabled]
    end
end
