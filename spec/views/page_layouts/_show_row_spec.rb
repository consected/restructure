# frozen_string_literal: true

require 'rails_helper'

# View spec for page_layouts/_show_row partial (issues #1180 and #1217).
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
#   - Singular resource name regression: when the page layout config uses a singular
#     name (e.g. 'activity_log__case_review'), the template name must still resolve
#     to the plural form matching the registered Handlebars template.
#
# Issue #1217 – URL params passthrough to report search criteria:
#   - When @filters contains keys that match a report's search_attributes, those
#     filter values are merged into the report URL's search_attrs query params.
#   - Filter keys that do NOT appear in the report's search_attributes are excluded
#     (allow-list safety).
#   - Static defaults from config are preserved when no matching URL param is provided.
#   - URL params take precedence over static defaults for the same key.
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
    # Handles both resource_name (plural) and resource_item_name (singular) lookups
    # to support the fallback path in resource_render_info.
    allow(Resources::Models).to receive(:find_by) do |args|
      if args[:resource_name]
        case args[:resource_name].to_s
        when 'activity_log__case_reviews' then activity_log_item
        when 'dynamic_model__contact_infos' then dynamic_model_item
        when 'scantron_ids' then external_id_item
        end
      elsif args[:resource_item_name]
        case args[:resource_item_name].to_s
        when 'activity_log__case_review' then activity_log_item
        when 'dynamic_model__contact_info' then dynamic_model_item
        end
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

  # --- Singular resource name regression (Bug #1180 fix) ---------------
  # _show_row.html.erb sets lookup_name to the un-pluralized config name
  # (e.g. 'activity_log__case_review'), then calls resource_render_info
  # with that singular name. Before the fix, resource_hyph used the caller's
  # input instead of the registry's canonical plural, producing a
  # data-template like 'activity-log--case-review-page-result-template'
  # which did not match any registered Handlebars template.

  context 'when the resource config name is singular (activity log)' do
    before do
      render partial: 'page_layouts/show_row',
             locals: { rows: resource_rows('activity_log__case_review'), container: container }
    end

    it 'resolves to the plural template name matching the registered Handlebars template' do
      expect(rendered).to include('data-template="activity-log--case-reviews-page-result-template"')
    end

    it 'does NOT use the singular form in the template name' do
      expect(rendered).not_to include('data-template="activity-log--case-review-page-result-template"')
    end
  end

  context 'when the resource config name is singular (dynamic model)' do
    before do
      render partial: 'page_layouts/show_row',
             locals: { rows: resource_rows('dynamic_model__contact_info'), container: container }
    end

    it 'resolves to the plural template name matching the registered Handlebars template' do
      expect(rendered).to include('data-template="dynamic-model--contact-infos-list-template"')
    end

    it 'does NOT use the singular form in the template name' do
      expect(rendered).not_to include('data-template="dynamic-model--contact-info-list-template"')
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

  # --- Issue #1217: URL params passthrough to report search criteria ---

  # Helper to build a minimal rows structure with one col containing a report.
  def report_rows(report_id, defaults: {})
    report_def = { 'id' => report_id, 'defaults' => defaults }
    [{ 'cols' => [{ 'label' => 'Report Label', 'report' => report_def }] }]
  end

  let(:mock_report) do
    instance_double(Report, search_attributes: {
                      'some_field' => [{ 'text' => nil }],
                      'another_field' => [{ 'text' => nil }]
                    })
  end

  context 'with a report block and URL filter params matching declared search_attributes' do
    before do
      assign(:filters, { 'some_field' => 'test_value' })
      allow(Report).to receive(:find_by_id_or_resource_name).with(42).and_return(mock_report)

      render partial: 'page_layouts/show_row',
             locals: { rows: report_rows(42), container: container }
    end

    it 'includes the filter value in the report URL search_attrs' do
      expect(rendered).to include('search_attrs%5Bsome_field%5D=test_value')
    end
  end

  context 'with a report block and URL filter params NOT in search_attributes (safety check)' do
    before do
      assign(:filters, { 'undeclared_field' => 'injected' })
      allow(Report).to receive(:find_by_id_or_resource_name).with(42).and_return(mock_report)

      render partial: 'page_layouts/show_row',
             locals: { rows: report_rows(42), container: container }
    end

    it 'does NOT include the undeclared filter key in the report URL' do
      expect(rendered).not_to include('undeclared_field')
    end
  end

  context 'with a report block and static defaults preserved when no URL param matches' do
    before do
      assign(:filters, {})
      allow(Report).to receive(:find_by_id_or_resource_name).with(42).and_return(mock_report)

      render partial: 'page_layouts/show_row',
             locals: { rows: report_rows(42, defaults: { 'some_field' => 'default_val' }), container: container }
    end

    it 'includes the static default value in the report URL' do
      expect(rendered).to include('search_attrs%5Bsome_field%5D=default_val')
    end
  end

  context 'with a report block and URL params overriding static defaults' do
    before do
      assign(:filters, { 'some_field' => 'url_override' })
      allow(Report).to receive(:find_by_id_or_resource_name).with(42).and_return(mock_report)

      render partial: 'page_layouts/show_row',
             locals: { rows: report_rows(42, defaults: { 'some_field' => 'default_val' }), container: container }
    end

    it 'uses the URL param value overriding the static default' do
      expect(rendered).to include('search_attrs%5Bsome_field%5D=url_override')
    end

    it 'does NOT include the overridden static default value' do
      expect(rendered).not_to include('default_val')
    end
  end

  context 'with a report block but no @filters assigned' do
    before do
      # @filters is nil (no URL params)
      allow(Report).to receive(:find_by_id_or_resource_name).with(42).and_return(mock_report)

      render partial: 'page_layouts/show_row',
             locals: { rows: report_rows(42, defaults: { 'some_field' => 'static_only' }), container: container }
    end

    it 'uses static defaults when no filters are present' do
      expect(rendered).to include('search_attrs%5Bsome_field%5D=static_only')
    end
  end

  context 'with a report block when report lookup fails (raises RecordNotFound)' do
    before do
      assign(:filters, { 'some_field' => 'injected' })
      allow(Report).to receive(:find_by_id_or_resource_name).with(42).and_raise(ActiveRecord::RecordNotFound)

      render partial: 'page_layouts/show_row',
             locals: { rows: report_rows(42, defaults: { 'static' => 'val' }), container: container }
    end

    it 'falls back to static defaults when report lookup fails' do
      expect(rendered).to include('search_attrs%5Bstatic%5D=val')
    end

    it 'does NOT include the URL filter value since report could not be verified' do
      expect(rendered).not_to include('injected')
    end
  end

  context 'with a report block when report lookup returns nil' do
    before do
      assign(:filters, { 'some_field' => 'injected' })
      allow(Report).to receive(:find_by_id_or_resource_name).with('my-report').and_return(nil)

      render partial: 'page_layouts/show_row',
             locals: { rows: report_rows('my-report', defaults: { 'static' => 'val' }), container: container }
    end

    it 'falls back to static defaults when report lookup returns nil' do
      expect(rendered).to include('search_attrs%5Bstatic%5D=val')
    end

    it 'does NOT include the URL filter value since report could not be verified' do
      expect(rendered).not_to include('injected')
    end
  end
end
