# frozen_string_literal: true

module Formatter
  #
  # Generate markup for a button to add an item (dynamic model, external id or core model) within a modal popup
  module AddItemButton
    def self.markup(model_name, master_id)
      hyph_name = model_name.hyphenate
      master_pre = "/masters/#{master_id}" if master_id

      html = <<~END_HTML
        <span class="temp-new-embedded-block">
          <div class="report-temp-embedded-block" id="#{hyph_name}--" data-subscription="#{hyph_name}-edit-form--" data-preprocessor="report_embed_dynamic_block" data-model-name="#{model_name}"></div>
          <a href="#{master_pre}/#{model_name.pluralize}/new" data-toggle="scrollto-result" data-target="##{hyph_name.pluralize}--" data-remote="true" class="btn btn-sm btn-primary add-item-button">
            <span class="glyphicon glyphicon-plus"></span>
          </a>
        </span>
      END_HTML

      html.html_safe
    end
  end
end
