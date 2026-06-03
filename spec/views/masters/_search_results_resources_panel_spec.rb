# frozen_string_literal: true

require 'rails_helper'

# View spec for masters/_search_results_resources_panel partial.
#
# The partial renders the outer collapsible container for a contains.resources
# page-layout panel.  The outer container `id`, its close-button `href`, and its
# CSS class suffix are all derived from `panel_name`.
#
# Regression (issue #1200): when `panel_name` contains spaces the generated
# `id` and `href` attributes were invalid HTML / broken CSS selectors, preventing
# Bootstrap collapse from firing.  The fix applies `.id_hyphenate` to every
# place `panel_name` is used as an HTML id or CSS selector target.  The
# `data-panel-tab` attribute on individual resource loader anchors is NOT
# hyphenated – it is compared as a value, not used as a selector.

RSpec.describe 'masters/_search_results_resources_panel', type: :view do
  # --- shared doubles -------------------------------------------------

  let(:activity_log_item) do
    Resources::Models::Item.new.merge(
      type: :activity_log,
      resource_name: 'activity_log__case_reviews',
      hyphenated_name: 'activity-log--case-reviews',
      base_route_segments: 'activity_log/case_reviews'
    )
  end

  let(:render_info_for_case_reviews) do
    {
      resource_name: 'activity_log__case_reviews',
      route_path: 'activity_log/case_reviews',
      template_name: 'activity-log--case-reviews-main-result-template',
      wrapper_class: 'activity-logs-generic-block',
      viewable_key: :activity_log__case_reviews
    }
  end

  def make_panel(panel_name:, panel_label: 'Test Panel', resources: ['activity_log__case_reviews'])
    contains_double = double('contains', resources: resources)
    view_options_double = double('view_options',
                                 default_expander: nil,
                                 hide_sublist_controls: false,
                                 hide_activity_logs_header: false,
                                 limit: 20)
    double('panel',
           panel_name: panel_name,
           panel_label: panel_label,
           contains: contains_double,
           view_options: view_options_double,
           view_css: nil)
  end

  before do
    allow(Resources::Models).to receive(:find_by) do |args|
      case args[:resource_name].to_s
      when 'activity_log__case_reviews' then activity_log_item
      else nil
      end
    end

    allow(view).to receive(:master_viewables).and_return(activity_log__case_reviews: true)
    allow(view).to receive(:resource_render_info).and_return(render_info_for_case_reviews)
    allow(view).to receive(:hide_player_tabs?).and_return(false)

    stub_template 'reports/_insert_options_css.html.erb' => ''
  end

  # --- Standard panel_name (no spaces) --------------------------------

  context 'with a simple hyphenated panel_name (e.g. "test-panel")' do
    before do
      render partial: 'masters/search_results_resources_panel',
             locals: { panel: make_panel(panel_name: 'test-panel', panel_label: 'Test Panel') }
    end

    it 'sets the outer div id from the panel_name' do
      expect(rendered).to include('id="test-panel-{{id}}"')
    end

    it 'sets the close-button href from the panel_name' do
      expect(rendered).to include('href="#test-panel-{{id}}"')
    end

    it 'includes the panel_name CSS block class' do
      expect(rendered).to include('test-panel-block')
    end
  end

  # --- Panel name with spaces (regression: panel IDs must be valid CSS) ---

  context 'with a panel_name that contains spaces (e.g. "phone log")' do
    before do
      render partial: 'masters/search_results_resources_panel',
             locals: { panel: make_panel(panel_name: 'phone log', panel_label: 'Phone Log') }
    end

    it 'uses a hyphenated id on the outer collapse div (no spaces in id attribute)' do
      expect(rendered).to include('id="phone-log-{{id}}"')
      expect(rendered).not_to include('id="phone log-')
    end

    it 'uses a hyphenated fragment in the close-button href (valid CSS selector)' do
      expect(rendered).to include('href="#phone-log-{{id}}"')
      expect(rendered).not_to include('href="#phone log-')
    end

    it 'uses a hyphenated CSS block class (no spaces in class attribute)' do
      expect(rendered).to include('phone-log-block')
      expect(rendered).not_to include('phone log-block')
    end

    it 'renders the resource loader anchor with the route path' do
      expect(rendered).to include('activity_log/case_reviews')
    end

    it 'renders the on-open-click hidden loader div' do
      expect(rendered).to include('on-open-click hidden')
    end
  end
end
