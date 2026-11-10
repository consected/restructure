# frozen_string_literal: true

# Verifies condition linter warnings for conditional-calculation perspectives
# are visible in the page-layout details panel.
require 'rails_helper'

RSpec.describe 'admin/page_layouts/_def_details.html.erb', type: :view do
  it 'shows condition configuration notices with the configuration snippet of the problem' do
    page_layout = Admin::PageLayout.new(
      layout_name: 'master',
      panel_name: 'condition-linter-test',
      panel_label: 'Condition Linter Test',
      options: <<~YAML
        view_options:
          perspectives:
            addresses:
              - conditional_calculation:
                  missing_linter_table:
                    missing_linter_field: return_value
      YAML
    )

    render partial: 'admin/page_layouts/def_details', locals: { object_instance: page_layout }

    fragment = Nokogiri::HTML.fragment(rendered)
    notice_types = fragment.css('.config-error-list-type').map { |node| node.text.strip }
    expect(notice_types).to include('condition configuration')
    expect(rendered).to include('missing_linter_table')

    snippets = fragment.css('.ceb-config-def pre').map(&:text).join("\n")
    expect(snippets).to include('perspectives:', 'missing_linter_table:', 'missing_linter_field: return_value')
  end
end
