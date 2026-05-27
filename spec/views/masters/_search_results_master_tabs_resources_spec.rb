# frozen_string_literal: true

require 'rails_helper'

# View spec for masters/_search_results_master_tabs_resources partial (issue #1180).
#
# Unified contract (consistent with contains.categories): the partial renders a
# SINGLE <li> tab per page-layout panel, regardless of how many resources the
# panel lists in contains.resources. The tab toggles a single outer collapse
# container whose id is derived from the panel_name. The actual per-resource
# `data-template` attributes live on inner blocks rendered by the sibling
# `_search_results_resources_panel` partial, not on the tab.
#
# Regression: single-resource panels (e.g. one activity log) continue to render
# exactly one tab with the same panel_label visible to the user.

RSpec.describe 'masters/_search_results_master_tabs_resources', type: :view do
  let(:activity_log_item) do
    Resources::Models::Item.new.merge(
      type: :activity_log,
      resource_name: 'activity_log__case_reviews',
      hyphenated_name: 'activity-log--case-reviews',
      base_route_segments: 'activity_log/case_reviews'
    )
  end

  let(:dynamic_model_item) do
    Resources::Models::Item.new.merge(
      type: :dynamic_model,
      resource_name: 'dynamic_model__contact_infos',
      hyphenated_name: 'contact-infos',
      base_route_segments: 'dynamic_model/contact_infos'
    )
  end

  let(:external_id_item) do
    Resources::Models::Item.new.merge(
      type: :external_identifier,
      resource_name: 'scantron_ids',
      hyphenated_name: 'scantron-ids',
      base_route_segments: 'scantron_ids'
    )
  end

  before do
    allow(Resources::Models).to receive(:find_by) do |args|
      case args[:resource_name].to_s
      when 'activity_log__case_reviews' then activity_log_item
      when 'dynamic_model__contact_infos' then dynamic_model_item
      when 'scantron_ids' then external_id_item
      else nil
      end
    end
  end

  let(:base_locals) do
    {
      panel_name: 'test-panel',
      panel_label: 'Test Panel',
      default_panels: [],
      initial_show: nil,
      close_others: false,
      filter_items: nil,
      limit: 20
    }
  end

  # --- Single resource (regression: AC-001/AC-002/AC-003) -------------

  context 'with a single dynamic model resource' do
    before do
      render partial: 'masters/search_results_master_tabs_resources',
             locals: base_locals.merge(resources: ['dynamic_model__contact_infos'])
    end

    it 'renders exactly one tab <li>' do
      expect(rendered.scan(/<li\b/).length).to eq(1)
    end

    it "uses the panel_name as the tab's data-panel-tab attribute" do
      expect(rendered).to include('data-panel-tab="test-panel"')
    end

    it "uses the panel_name as the tab's collapse target" do
      expect(rendered).to include('data-target="#test-panel-{{id}}"')
    end

    it 'displays the panel_label as the tab text' do
      expect(rendered).to include('Test Panel')
    end

    it 'does not place a data-template attribute on the tab itself' do
      # data-template lives on the inner resource block, not on the tab.
      expect(rendered).not_to include('data-template=')
    end
  end

  context 'with a single activity log resource (regression)' do
    before do
      render partial: 'masters/search_results_master_tabs_resources',
             locals: base_locals.merge(resources: ['activity_log__case_reviews'])
    end

    it 'renders exactly one tab <li>' do
      expect(rendered.scan(/<li\b/).length).to eq(1)
    end

    it 'targets the panel_name-keyed collapse container' do
      expect(rendered).to include('data-target="#test-panel-{{id}}"')
    end
  end

  context 'with a single external identifier resource' do
    before do
      render partial: 'masters/search_results_master_tabs_resources',
             locals: base_locals.merge(resources: ['scantron_ids'])
    end

    it 'renders exactly one tab <li>' do
      expect(rendered.scan(/<li\b/).length).to eq(1)
    end

    it 'targets the panel_name-keyed collapse container' do
      expect(rendered).to include('data-target="#test-panel-{{id}}"')
    end
  end

  # --- Multiple resources in a single panel (AC-004) ------------------

  context 'with multiple resources in the same panel' do
    before do
      render partial: 'masters/search_results_master_tabs_resources',
             locals: base_locals.merge(
               resources: [
                 'activity_log__case_reviews',
                 'dynamic_model__contact_infos',
                 'scantron_ids'
               ]
             )
    end

    it 'still renders exactly one tab <li> (mirrors categories behaviour)' do
      expect(rendered.scan(/<li\b/).length).to eq(1)
    end

    it 'uses the shared panel_name as the tab key and collapse target' do
      expect(rendered).to include('data-panel-tab="test-panel"')
      expect(rendered).to include('data-target="#test-panel-{{id}}"')
    end
  end

  # --- Unresolvable / no accessible resources (AC-005/AC-007) ---------

  context 'with no resolvable resources' do
    before do
      render partial: 'masters/search_results_master_tabs_resources',
             locals: base_locals.merge(resources: ['nonexistent_resource'])
    end

    it 'renders no tab markup' do
      expect(rendered).not_to include('<li')
      expect(rendered).not_to include('<a ')
    end
  end
end
