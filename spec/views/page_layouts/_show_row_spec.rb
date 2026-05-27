# frozen_string_literal: true

require 'rails_helper'

# View spec for page_layouts/_show_row partial (issue #1180).
#
# The partial renders standalone-page column resource blocks.  The key rendered
# attributes under test are:
#   - data-template on the inner <div>: must use the Handlebars template registered
#     for the resource type rather than the naive "hyphenated_resource-page-result-template"
#     pattern the current implementation produces.
#   - CSS wrapper classes: must include the resource-type-specific generic block class
#     (dynamic-model-generic-block, external-id-generic-block, activity-logs-generic-block)
#     in addition to the always-present standalone-panel-generic-block.
#
# RED-phase contract:
#   - Dynamic model default (no template_prefix):
#       expected: data-template="dynamic-model--contact-infos-list-template"
#   - External identifier default:
#       expected: data-template="scantron-ids-list-template"
#   - Activity log regression (AC-020): current behaviour is unchanged.
#   - Explicit template_prefix override (AC-023): prefix takes precedence over type default.
#
# The partial consumes @master_id and two locals: rows and container.
# Formatter::Substitution and markdown_to_html are stubbed to avoid DB/gem overhead.

RSpec.describe 'page_layouts/_show_row', type: :view do
  # --- shared test doubles / stubs -----------------------------------

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
    # Provide a master id so the partial can build URLs and skip the Not Found block.
    assign(:master_id, 123)
    assign(:master, {})

    # Stub Resources::Models.find_by for the new implementation.
    allow(Resources::Models).to receive(:find_by) do |args|
      case args[:resource_name].to_s
      when 'activity_log__case_reviews' then activity_log_item
      when 'dynamic_model__contact_infos' then dynamic_model_item
      when 'scantron_ids' then external_id_item
      else nil
      end
    end

    # Stub string-substitution helpers to return their input unchanged.
    allow(view).to receive(:markdown_to_html) { |text| text.to_s.html_safe }
    allow(Formatter::Substitution).to receive(:substitute) { |str, **_opts| str.to_s.html_safe }

    # Stub the error-page partial so it never triggers in the col rendering path.
    stub_template 'layouts/_error_page_block.erb' => ''
  end

  # Helper to build a minimal rows structure with one col containing a resource.
  def resource_rows(resource_name, extra_resource_opts: {})
    resource_def = { 'name' => resource_name }.merge(extra_resource_opts)
    [{ 'cols' => [{ 'label' => 'Test Label', 'resource' => resource_def }] }]
  end

  let(:container) { double('container') }

  # --- Dynamic model resource, no template_prefix (AC-021) ------------

  context 'with a dynamic model resource and no template_prefix' do
    before do
      render partial: 'page_layouts/show_row',
             locals: { rows: resource_rows('dynamic_model__contact_infos'), container: container }
    end

    it 'renders the inner div with data-template pointing to the stripped list template' do
      expect(rendered).to include('data-template="dynamic-model--contact-infos-list-template"')
    end

    it 'includes the dynamic-model-generic-block wrapper class on the inner div' do
      expect(rendered).to include('dynamic-model-generic-block')
    end

    it 'always includes the standalone-panel-generic-block wrapper class' do
      expect(rendered).to include('standalone-panel-generic-block')
    end

    it 'sets data-url to the dynamic_model master-scoped path' do
      expect(rendered).to match(%r{data-url=["'][^"']*masters/123/dynamic_model/contact_infos})
    end
  end

  # --- External identifier resource, no template_prefix (AC-022) ------

  context 'with an external identifier resource and no template_prefix' do
    before do
      render partial: 'page_layouts/show_row',
             locals: { rows: resource_rows('scantron_ids'), container: container }
    end

    it 'renders the inner div with data-template pointing to the list template' do
      expect(rendered).to include('data-template="scantron-ids-list-template"')
    end

    it 'includes the external-id-generic-block wrapper class on the inner div' do
      expect(rendered).to include('external-id-generic-block')
    end

    it 'always includes the standalone-panel-generic-block wrapper class' do
      expect(rendered).to include('standalone-panel-generic-block')
    end

    it 'sets data-url to the scantron_ids master-scoped path' do
      expect(rendered).to match(%r{data-url=["'][^"']*masters/123/scantron_ids})
    end
  end

  # --- Activity log resource, no template_prefix — regression (AC-020) -

  context 'with an activity log resource and no template_prefix (regression)' do
    before do
      render partial: 'page_layouts/show_row',
             locals: { rows: resource_rows('activity_log__case_reviews'), container: container }
    end

    it 'renders the inner div with data-template using the default page-result-template suffix' do
      expect(rendered).to include('data-template="activity-log--case-reviews-page-result-template"')
    end

    it 'includes the activity-logs-generic-block wrapper class' do
      expect(rendered).to include('activity-logs-generic-block')
    end

    it 'always includes the standalone-panel-generic-block wrapper class' do
      expect(rendered).to include('standalone-panel-generic-block')
    end
  end

  # --- Explicit template_prefix override (AC-023) ----------------------

  context 'with a dynamic model resource and an explicit template_prefix' do
    before do
      render partial: 'page_layouts/show_row',
             locals: {
               rows: resource_rows('dynamic_model__contact_infos',
                                   extra_resource_opts: { 'template_prefix' => 'page' }),
               container: container
             }
    end

    it 'uses the explicit prefix to build the template name overriding the type default' do
      expect(rendered).to include('data-template="dynamic-model--contact-infos-page-result-template"')
    end
  end

  # --- Unresolvable resource name (AC-024) ----------------------------

  context 'with an unresolvable resource name' do
    before do
      render partial: 'page_layouts/show_row',
             locals: { rows: resource_rows('nonexistent_resource'), container: container }
    end

    it 'renders without raising an exception' do
      # The example itself passing without an exception satisfies this criterion.
      expect(rendered).not_to be_nil
    end

    it 'does not include a broken data-template referencing the raw resource name' do
      expect(rendered).not_to include('data-template="nonexistent-resource-')
    end
  end
end
