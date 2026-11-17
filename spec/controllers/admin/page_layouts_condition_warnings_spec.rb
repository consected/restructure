# frozen_string_literal: true

# Verifies that condition configuration notices for a persisted page layout are shown on the admin edit panel,
# with the configuration snippet of each perspective item that has a problem. Notices are shown for every
# perspective item, and the default_perspective is kept alongside them. Notices never block saving.
require 'rails_helper'

RSpec.describe Admin::PageLayoutsController, type: :controller do
  include MasterSupport

  render_views

  before_each_login_admin

  let(:perspectives_options) do
    <<~YAML
      view_options:
        perspectives:
          addresses:
            - name: first
              label: First
              conditional_calculation:
                first_missing_table:
                  missing_linter_field: return_value
                  return: return_all_results
            - name: second
              label: Second
              conditional_calculation:
                second_missing_table:
                  missing_linter_field: return_value
                  return: return_all_results
        default_perspective: first
    YAML
  end

  let(:page_layout) do
    Admin::PageLayout.create!(layout_name: 'master', panel_name: 'condition-warning-page-layout',
                              panel_label: 'Condition Warning Page Layout', options: perspectives_options,
                              current_admin: @admin)
  end

  describe 'GET #edit' do
    it 'shows a condition configuration notice for each perspective item of a persisted page layout' do
      get :edit, params: { id: page_layout.id }

      expect(response).to have_http_status(:ok)
      fragment = Nokogiri::HTML.fragment(response.body)
      types = fragment.css('.config-error-list-type').map { |node| node.text.strip }
      expect(types.count(OptionConfigs::ConditionLintNotices::WARNING_TYPE)).to eq(2)
      expect(response.body).to include('first_missing_table', 'second_missing_table')
    end

    it 'shows the YAML configuration snippet of each perspective item with the problem' do
      get :edit, params: { id: page_layout.id }

      snippets = Nokogiri::HTML.fragment(response.body).css('.ceb-config-def pre').map(&:text).join("\n")
      expect(snippets).to include('first_missing_table:', 'second_missing_table:', 'missing_linter_field: return_value')
      expect(snippets).to include('- conditional_calculation:')
    end
  end
end
