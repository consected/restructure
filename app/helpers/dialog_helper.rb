module DialogHelper
  def link_to_dialog(config_or_name)
    dialog = find_dialog_by_config_or_name(config_or_name)
    if dialog
      txt = link_to link_label_open_in_new("#{dialog.category} - #{dialog.name}"),
                    admin_message_templates_path(filter: { id: dialog.id }, perform_action: 'edit'), target: '_blank'
    else
      name = dialog_name_from(config_or_name)
      txt = <<~END_HTML
        Add a #{link_to(link_label_open_in_new("new dialog for '#{name}'"), admin_message_templates_path(init_with: { message_type: 'dialog', template_type: 'content', category: object_instance.category, name: name }, perform_action: 'new'), target: '_blank').html_safe}
        with <i>message type:</i> <b>dialog</b>, <i>template type:</i> <b>content</b> &amp;  <i>name:</i> <b>#{name}</b>
      END_HTML
    end
    txt.html_safe
  end

  def find_dialog_by_config_or_name(config_or_name)
    name = dialog_name_from(config_or_name)

    Admin::MessageTemplate.active.find_by(name: name)
  end

  private

  # Extract the template name from a dialog_before value, which may be a plain
  # String, a plain Hash, or an OptionConfigs::BaseNamedConfiguration instance
  # (Hash-like via #[], but not a Hash subclass).
  # @param [String | Hash | OptionConfigs::BaseNamedConfiguration] config_or_name
  # @return [String | nil]
  def dialog_name_from(config_or_name)
    return config_or_name if config_or_name.is_a?(String)
    return unless config_or_name.respond_to?(:[])

    config_or_name[:name] || config_or_name['name']
  end
end
