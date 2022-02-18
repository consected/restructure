# frozen_string_literal: true

module Formatter
  #
  # Generate markup for a button to add an item (dynamic model, external id or core model) within a modal popup
  module AddItemButton
    def self.markup(model_name, master_id)
      master_pre = "/masters/#{master_id}" if master_id

      path = model_name.ns_pathify
      parts = path.split('/')

      case parts.length
      when 2
        hyph_name = model_name.hyphenate
      when 3
        path = "#{parts[0]}/#{parts[1].pluralize}/#{parts[2]}"
        hyph_name = "#{parts[0..1].join('--').hyphenate}-#{parts[2].hyphenate}"
      else
        hyph_name = model_name.hyphenate
        path = path.pluralize
      end

      html = <<~END_HTML
        <span class="temp-new-embedded-block">
          <a href="#{master_pre}/#{path}/new"
             data-toggle="scrollto-result"
             data-target="##{hyph_name.pluralize}-#{master_id}-"
             data-remote="true"
             class="btn btn-sm btn-primary add-item-button"
          >
            <span class="glyphicon glyphicon-plus"></span>
          </a>
          <span class="report-temp-embedded-block show-no-result"
               id="#{hyph_name}-#{master_id}-"
               data-subscription="#{hyph_name}-edit-form-#{master_id}-"
               data-preprocessor="report_embed_dynamic_block"
               data-model-name="#{model_name}"
          >
          </span>
        </span>
      END_HTML

      html.html_safe
    end
  end
end
