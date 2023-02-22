class Admin::MessageTemplatesController < AdminController
  helper_method :message_type_options, :template_type_options
  before_action :set_defaults

  protected

  def view_folder
    'admin/message_templates'
  end

  def set_defaults
    @show_again_on_save = true
  end

  def filters
    {
      category: Admin::MessageTemplate.pluck(:category).uniq.compact,
      message_type: Admin::MessageTemplate.message_types.map(&:to_s),
      template_type: Admin::MessageTemplate.template_types.map(&:to_s)
    }
  end

  def filters_on
    %i[category message_type template_type]
  end

  def default_index_order
    { name: :asc }
  end

  def template_type_options
    Admin::MessageTemplate.template_types
  end

  def message_type_options
    Admin::MessageTemplate.message_types
  end

  def editor_code_type
    return 'markdown' if object_instance&.force_markdown_to_html
    return 'text' if object_instance&.message_type == 'sms'
    return 'css' if object_instance&.name&.start_with?('ui page css')
    return 'javascript' if object_instance&.name&.start_with?('ui page js')

    'htmlmixed'
  end

  private

  def permitted_params
    %i[name category message_type template_type template disabled]
  end
end
