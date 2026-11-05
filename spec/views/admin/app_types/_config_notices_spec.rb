# frozen_string_literal: true

# Verifies that the app type components page shows each condition configuration notice of a page layout
# with its YAML configuration snippet, so the administrator can find the problem in the configuration.
require 'rails_helper'

RSpec.describe 'admin/app_types/_config_notices.html.erb', type: :view do
  let(:page_layout) do
    Admin::PageLayout.new(
      layout_name: 'master',
      panel_name: 'app-type-notice-test',
      panel_label: 'App Type Notice Test',
      options: <<~YAML
        view_options:
          perspectives:
            addresses:
              - name: open
                conditional_calculation:
                  missing_linter_table:
                    missing_linter_field: return_value
      YAML
    )
  end

  it 'shows the condition configuration notice type and its configuration snippet' do
    assign(:config_notices, OptionConfigs::ExtraOptions.all_option_configs_notices(page_layout))

    render partial: 'admin/app_types/config_notices'

    fragment = Nokogiri::HTML.fragment(rendered)
    expect(fragment.css('.app-type-config-notices-head-link').map(&:text).join)
      .to include(OptionConfigs::ConditionLintNotices::WARNING_TYPE)
    snippets = fragment.css('.config-notice pre').map(&:text).join("\n")
    expect(snippets).to include('perspectives:', 'missing_linter_table:', 'missing_linter_field: return_value')
    expect(fragment.css('.config-notice p').map(&:text).join).to include("'missing_linter_table' is not a known resource")
  end
end
