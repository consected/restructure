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
                                 limit: 20,
                                 perspectives: nil,
                                 default_perspective: nil)
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
      end
    end

    allow(Admin::AppConfiguration).to receive(:hash_for).and_return({})

    allow(view).to receive(:current_user).and_return(nil)
    allow(view).to receive(:master_viewables).and_return(activity_log__case_reviews: true)
    allow(view).to receive(:resource_render_info).and_return(render_info_for_case_reviews)
    allow(view).to receive(:hide_player_tabs?).and_return(false)

    stub_template 'reports/_insert_options_css.html.erb' => ''
  end

  # --- Single activity-log resource: legacy mode (issue #1205) --------
  #
  # Single-resource panels must render WITHOUT the outer collapsible wrapper
  # introduced by PR #1182. The resource block is rendered directly with its
  # own resource-keyed id, not a panel_name-keyed id.

  context 'with a simple hyphenated panel_name (e.g. "test-panel") — single AL resource legacy mode' do
    before do
      render partial: 'masters/search_results_resources_panel',
             locals: { panel: make_panel(panel_name: 'test-panel', panel_label: 'Test Panel') }
    end

    it 'does NOT render the outer panel-default wrapper div (legacy mode: no outer wrapper)' do
      expect(rendered).not_to include('class="panel panel-default section-panel')
    end

    it 'does NOT render an <h4> heading (AL has its own heading)' do
      expect(rendered).not_to include('<h4')
    end

    it 'does NOT render the on-open-click hidden loader div (no deferred loader in legacy mode)' do
      expect(rendered).not_to include('on-open-click hidden')
    end

    it 'renders the resource block with a resource-keyed id (not panel_name-keyed)' do
      expect(rendered).to include('id="activity-log--case-reviews-{{id}}"')
      expect(rendered).not_to include('id="test-panel-{{id}}"')
    end

    it 'renders the resource block with the legacy wrapper + resource-hyphenated class' do
      expect(rendered).to include('activity-logs-generic-block activity-log--case-reviews-block')
    end

    it 'renders data-sub-item with the resource name' do
      expect(rendered).to include('data-sub-item="activity_log__case_reviews"')
    end

    it 'renders data-template directly on the resource block (not on a separate loader anchor)' do
      expect(rendered).to include('data-template="activity-log--case-reviews-main-result-template"')
    end

    it 'renders the inner block with a resource-keyed id' do
      expect(rendered).to include('id="activity-log--case-reviews-inner-{{id}}"')
    end
  end

  # --- Single AL resource with spaces in panel_name: still resource-keyed ---

  context 'with a panel_name that contains spaces (e.g. "phone log") — single AL resource legacy mode' do
    before do
      render partial: 'masters/search_results_resources_panel',
             locals: { panel: make_panel(panel_name: 'phone log', panel_label: 'Phone Log') }
    end

    it 'does NOT render the outer panel-default wrapper div' do
      expect(rendered).not_to include('class="panel panel-default section-panel')
    end

    it 'does NOT render an <h4> heading' do
      expect(rendered).not_to include('<h4')
    end

    it 'does NOT render the on-open-click hidden loader div' do
      expect(rendered).not_to include('on-open-click hidden')
    end

    it 'renders the resource block with a resource-keyed id (panel_name not in the id)' do
      expect(rendered).to include('id="activity-log--case-reviews-{{id}}"')
      expect(rendered).not_to include('id="phone-log-{{id}}"')
      expect(rendered).not_to include('id="phone log-')
    end

    it 'renders the resource loader route path' do
      expect(rendered).to include('activity_log/case_reviews')
    end
  end

  # --- Single dynamic model resource: wrapper mode (issue #1180) --------

  context 'with a single dynamic model resource — wrapper mode' do
    let(:dynamic_model_item) do
      Resources::Models::Item.new.merge(
        type: :dynamic_model,
        resource_name: 'dynamic_model__contact_infos',
        hyphenated_name: 'dynamic-model--contact-infos',
        base_route_segments: 'dynamic_model/contact_infos'
      )
    end

    let(:render_info_for_contact_infos) do
      {
        resource_name: 'dynamic_model__contact_infos',
        route_path: 'dynamic_model/contact_infos',
        template_name: 'dynamic-model--contact-infos-list-template',
        wrapper_class: 'dynamic-model-generic-block',
        viewable_key: :dynamic_model__contact_infos
      }
    end

    before do
      allow(Resources::Models).to receive(:find_by) do |args|
        case args[:resource_name].to_s
        when 'dynamic_model__contact_infos' then dynamic_model_item
        end
      end

      allow(view).to receive(:master_viewables).and_return(dynamic_model__contact_infos: true)
      allow(view).to receive(:resource_render_info).and_return(render_info_for_contact_infos)

      render partial: 'masters/search_results_resources_panel',
             locals: { panel: make_panel(panel_name: 'contacts-panel',
                                         panel_label: 'Contacts',
                                         resources: ['dynamic_model__contact_infos']) }
    end

    it 'renders the outer panel-default wrapper div (wrapper mode: outer container)' do
      expect(rendered).to include('class="panel panel-default section-panel')
    end

    it 'renders an <h4> heading with the panel label' do
      expect(rendered).to include('<h4')
    end

    it 'renders the on-open-click hidden loader div (fires AJAX when panel opens)' do
      expect(rendered).to include('on-open-click hidden')
    end

    it 'renders the outer div with panel_name-keyed id and inner resource block with resource-keyed id' do
      expect(rendered).to include('id="contacts-panel-{{id}}"')
      expect(rendered).to include('id="dynamic-model--contact-infos-{{id}}"')
    end

    it 'renders the resource block with the DM wrapper + resource-hyphenated class' do
      expect(rendered).to include('dynamic-model-generic-block dynamic-model--contact-infos-block')
    end

    it 'renders data-sub-item with the DM resource name' do
      expect(rendered).to include('data-sub-item="dynamic_model__contact_infos"')
    end

    it 'renders data-template with the DM list template directly on the resource block' do
      expect(rendered).to include('data-template="dynamic-model--contact-infos-list-template"')
    end

    it 'renders the inner block with a resource-keyed id' do
      expect(rendered).to include('id="dynamic-model--contact-infos-inner-{{id}}"')
    end
  end
end
