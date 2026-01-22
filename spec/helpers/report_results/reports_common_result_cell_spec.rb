# frozen_string_literal: true

# ReportsCommonResultCell Spec
#
# Tests the cell content rendering for report table cells, specifically focusing on
# the embedded_block feature that displays dynamic model and activity log records
# in a modal dialog when clicked.
#
# Test Coverage:
# - #cell_content_for_embedded_block: Generates HTML for opening records in a modal
#   - Handles plain URLs like /dynamic_model/table_name/123
#   - Handles markdown format links like [Label](/dynamic_model/table_name/123)
#   - Handles activity log URLs like /activity_log/log_type/456
#   - NEW: Handles edit mode URLs ending with /edit (GitHub #325)
#     - /dynamic_model/table_name/123/edit should include data-edit-mode="true"
#     - Modal should open directly in edit mode
#     - Save should close the modal dialog

require 'rails_helper'

RSpec.describe ReportResults::ReportsCommonResultCell do
  let(:table_name) { 'dynamic_model__test_items' }
  let(:col_name) { 'edit_link' }
  let(:col_tag) { nil }
  let(:col_show_as) { 'embedded_block' }
  let(:selection_options) { double('selection_options') }

  def build_cell(content)
    described_class.new(table_name, content, col_name, col_tag, col_show_as, selection_options)
  end

  describe '#cell_content_for_embedded_block' do
    context 'with dynamic model show URLs (existing behavior)' do
      it 'returns the content unchanged if blank' do
        cell = build_cell('')
        expect(cell.cell_content_for_embedded_block).to eq('')
      end

      it 'returns nil if content is nil' do
        cell = build_cell(nil)
        expect(cell.cell_content_for_embedded_block).to be_nil
      end

      it 'parses plain URL and generates correct HTML with show mode attributes' do
        url = '/dynamic_model/datadic_variables/123'
        cell = build_cell(url)
        html = cell.cell_content_for_embedded_block

        # Should contain the link
        expect(html).to include('href="/dynamic_model/datadic_variables/123"')
        expect(html).to include('data-remote="true"')
        expect(html).to include('class="report-embedded-block-link glyphicon glyphicon-tasks"')

        # Should contain the hidden div for the modal content
        expect(html).to include('id="report-result-embedded-block--123"')
        expect(html).to include('data-preprocessor="report_embed_dynamic_block"')
        expect(html).to include('data-model-name="dynamic_model__datadic_variable"')
        expect(html).to include('data-id="123"')

        # Should NOT contain edit-mode attribute (show mode)
        expect(html).not_to include('data-edit-mode')
      end

      it 'parses markdown format link correctly' do
        url = '[Edit Item](/dynamic_model/datadic_variables/456)'
        cell = build_cell(url)
        html = cell.cell_content_for_embedded_block

        # Should contain the link text
        expect(html).to include('>Edit Item</a>')
        expect(html).to include('href="/dynamic_model/datadic_variables/456"')

        # Should have correct id
        expect(html).to include('data-id="456"')
        expect(html).to include('id="report-result-embedded-block--456"')

        # Should NOT contain edit-mode attribute
        expect(html).not_to include('data-edit-mode')
      end

      it 'extracts master_id from URL when present' do
        url = '/masters/789/dynamic_model/test_items/123'
        cell = build_cell(url)
        html = cell.cell_content_for_embedded_block

        expect(html).to include('data-master-id="789"')
        expect(html).to include('data-id="123"')
      end

      it 'generates correct hyphenated model name for dynamic models' do
        url = '/dynamic_model/datadic_variables/123'
        cell = build_cell(url)
        html = cell.cell_content_for_embedded_block

        # dynamic_model + datadic_variables -> dynamic_model__datadic_variable (singularized, hyphenated)
        expect(html).to include('data-model-name="dynamic_model__datadic_variable"')
        expect(html).to include('data-dynamic-model--datadic-variable-id="123"')
      end
    end

    context 'with activity log show URLs (existing behavior)' do
      it 'parses activity log URL and generates correct HTML' do
        url = '/activity_log/test_processes/456'
        cell = build_cell(url)
        html = cell.cell_content_for_embedded_block

        expect(html).to include('href="/activity_log/test_processes/456"')
        expect(html).to include('data-id="456"')
        expect(html).to include('data-model-name="activity_log__test_process"')

        # Should NOT contain edit-mode attribute
        expect(html).not_to include('data-edit-mode')
      end
    end

    context 'with edit mode URLs ending in /edit (GitHub #325)' do
      it 'parses dynamic model edit URL and includes edit-mode attribute' do
        url = '/dynamic_model/datadic_variables/123/edit'
        cell = build_cell(url)
        html = cell.cell_content_for_embedded_block

        # Should extract the correct id (not "edit")
        expect(html).to include('data-id="123"')
        expect(html).not_to include('data-id="edit"')

        # Should include edit-mode attribute
        expect(html).to include('data-edit-mode="true"')

        # Should still have correct model name
        expect(html).to include('data-model-name="dynamic_model__datadic_variable"')

        # Should have the full URL including /edit
        expect(html).to include('href="/dynamic_model/datadic_variables/123/edit"')
      end

      it 'parses markdown format edit URL correctly' do
        url = '[Edit Now](/dynamic_model/datadic_variables/789/edit)'
        cell = build_cell(url)
        html = cell.cell_content_for_embedded_block

        expect(html).to include('>Edit Now</a>')
        expect(html).to include('data-id="789"')
        expect(html).to include('data-edit-mode="true"')
        expect(html).not_to include('data-id="edit"')
      end

      it 'parses activity log edit URL and includes edit-mode attribute' do
        url = '/activity_log/test_processes/456/edit'
        cell = build_cell(url)
        html = cell.cell_content_for_embedded_block

        expect(html).to include('data-id="456"')
        expect(html).not_to include('data-id="edit"')
        expect(html).to include('data-edit-mode="true"')
        expect(html).to include('data-model-name="activity_log__test_process"')
      end

      it 'handles master_id correctly with edit URLs' do
        url = '/masters/999/dynamic_model/test_items/123/edit'
        cell = build_cell(url)
        html = cell.cell_content_for_embedded_block

        expect(html).to include('data-master-id="999"')
        expect(html).to include('data-id="123"')
        expect(html).to include('data-edit-mode="true"')
        expect(html).not_to include('data-id="edit"')
      end
    end
  end
end
