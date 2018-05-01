class Admin::MessageTemplatesController < AdminController

  protected
  def filters
    {
      message_type: MessageTemplate.message_types.map(&:to_s),
      template_type: MessageTemplate.template_types.map(&:to_s)
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
