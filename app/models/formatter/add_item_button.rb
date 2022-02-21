# frozen_string_literal: true

module Formatter
  #
  # Generate markup for a button to add an item (dynamic model, external id or core model) within a modal popup
  module AddItemButton
    def self.markup(resource_name, master_id)
      master_pre = "/masters/#{master_id}" if master_id

      model = Resources::Models.find_by(resource_name: resource_name)
      raise FphsException, "add_item_button configured resource name is not found: #{resource_name}" unless model

      path = model[:base_route_segments]
      hyph_name = model[:hyphenated_name]

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
               data-model-name="#{resource_name}"
          >
          </span>
        </span>
      END_HTML

      html.html_safe
    end
  end
end
