# frozen_string_literal: true

#
# Display field meanings from configuration _field_def.yaml files
module FieldMeaningsHelper
  def field_meanings
    return @field_meanings if @field_meanings
    return unless help_section.to_s

    fm = field_meaning_defs_for help_section.to_s.singularize
    return unless fm

    @field_meanings = {}
    fm.each do |k, v|
      @field_meanings[k.to_s.underscore] = v
    end

    @field_meanings
  end

  def field_meaning_for_key(key)
    name = key.to_s.humanize.underscore
    field_meanings[name]
  end

  def form_field_label(form, key)
    label = admin_labels[key.to_sym] || key.to_s.humanize

    res = form.label key, label
    return res unless field_meanings

    meaning = field_meaning_for_key(key)
    return res unless meaning

    meaning = h(meaning).gsub("\n", ' ')
    info_sign = <<~END_HTML
      <i class="glyphicon glyphicon-question-sign label-help-icon"
          data-toggle="popover"
          data-trigger="click hover"
          data-content="#{meaning}"
      ></i>
    END_HTML
                .html_safe

    safe_key = h(label)
    form.label key, "#{safe_key} #{info_sign}".html_safe
  end

  def field_meaning_defs_for(config_type)
    file_path = Rails.root.join('app', 'models', 'admin', 'defs', "#{config_type}_field_defs.yaml")
    return unless File.exist?(file_path)

    content = File.read(file_path)
    YAML.safe_load(content)
  end
end
