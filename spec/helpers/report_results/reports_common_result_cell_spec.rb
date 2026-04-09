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
#   - Handles edit mode URLs ending with /edit (GitHub #325)
# - #cell_content_for_url: Renders cell content as a link in a new tab (GitHub #1053)
#   - Handles markdown format [text](url) correctly
#   - Falls back to plain text when content doesn't match markdown link format
#   - Handles nil and blank content gracefully

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
    describe 'edge cases' do
      it 'returns blank content unchanged' do
        expect(build_cell('').cell_content_for_embedded_block).to eq('')
      end

      it 'returns nil content as nil' do
        expect(build_cell(nil).cell_content_for_embedded_block).to be_nil
      end
    end

    describe 'URL parsing' do
      shared_examples 'parses URL correctly' do |url, expected|
        it "extracts correct attributes from #{url}" do
          html = build_cell(url).cell_content_for_embedded_block

          expect(html).to include("data-id=\"#{expected[:id]}\"")
          expect(html).not_to include('data-id="edit"')
          expect(html).to include("data-model-name=\"#{expected[:model_name]}\"")

          expect(html).to include("data-master-id=\"#{expected[:master_id]}\"") if expected[:master_id]

          if expected[:edit_mode]
            expect(html).to include('data-edit-mode="true"')
          else
            expect(html).not_to include('data-edit-mode')
          end
        end
      end

      context 'with dynamic model URLs' do
        include_examples 'parses URL correctly',
                         '/dynamic_model/datadic_variables/123',
                         { id: '123', model_name: 'dynamic_model__datadic_variable', edit_mode: false }

        include_examples 'parses URL correctly',
                         '/masters/789/dynamic_model/test_items/456',
                         { id: '456', model_name: 'dynamic_model__test_item', master_id: '789', edit_mode: false }

        include_examples 'parses URL correctly',
                         '/dynamic_model/datadic_variables/123/edit',
                         { id: '123', model_name: 'dynamic_model__datadic_variable', edit_mode: true }

        include_examples 'parses URL correctly',
                         '/masters/999/dynamic_model/test_items/123/edit',
                         { id: '123', model_name: 'dynamic_model__test_item', master_id: '999', edit_mode: true }
      end

      context 'with activity log URLs' do
        include_examples 'parses URL correctly',
                         '/activity_log/test_processes/456',
                         { id: '456', model_name: 'activity_log__test_process', edit_mode: false }

        include_examples 'parses URL correctly',
                         '/activity_log/test_processes/456/edit',
                         { id: '456', model_name: 'activity_log__test_process', edit_mode: true }
      end
    end

    describe 'HTML generation' do
      it 'generates link with correct attributes for plain URL' do
        html = build_cell('/dynamic_model/datadic_variables/123').cell_content_for_embedded_block

        expect(html).to include('href="/dynamic_model/datadic_variables/123"')
        expect(html).to include('data-remote="true"')
        expect(html).to include('class="report-embedded-block-link glyphicon glyphicon-tasks"')
        expect(html).to include('data-preprocessor="report_embed_dynamic_block"')
      end

      it 'generates link with label for markdown format' do
        html = build_cell('[Edit Item](/dynamic_model/datadic_variables/456)').cell_content_for_embedded_block

        expect(html).to include('>Edit Item</a>')
        expect(html).to include('href="/dynamic_model/datadic_variables/456"')
      end

      it 'generates target div with correct id' do
        html = build_cell('/dynamic_model/test/789').cell_content_for_embedded_block

        expect(html).to include('id="report-result-embedded-block--789"')
        expect(html).to include('class="report-temp-embedded-block"')
      end

      it 'preserves full URL including /edit for edit mode' do
        html = build_cell('/dynamic_model/test/123/edit').cell_content_for_embedded_block

        expect(html).to include('href="/dynamic_model/test/123/edit"')
      end
    end
  end

  describe '#cell_content_for_url' do
    # Override col_show_as to 'url' for these tests
    let(:col_show_as) { 'url' }

    it 'renders markdown format [text](url) as a link' do
      html = build_cell('[Click here](https://example.com/page)').cell_content_for_url

      expect(html).to include('href="https://example.com/page"')
      expect(html).to include('>Click here</a>')
      expect(html).to include('target="_blank"')
    end

    it 'falls back to showing plain text when content is not markdown link format' do
      result = build_cell('just some plain text').cell_content_for_url

      expect(result).to eq('just some plain text')
    end

    it 'returns nil when content is nil' do
      result = build_cell(nil).cell_content_for_url

      expect(result).to be_nil
    end

    it 'returns blank content as-is when content is empty' do
      result = build_cell('').cell_content_for_url

      expect(result).to eq('')
    end

    it 'falls back to showing a plain URL as text when not in markdown format' do
      result = build_cell('https://example.com').cell_content_for_url

      expect(result).to eq('https://example.com')
    end

    it 'html-escapes the URL in the href attribute' do
      result = build_cell('[text](https://example.com/path?a=1&b=2)').cell_content_for_url

      expect(result).to include('href="https://example.com/path?a=1&amp;b=2"')
    end

    it 'falls back to plain text for javascript: protocol URLs' do
      result = build_cell('[click](javascript:alert(1))').cell_content_for_url

      expect(result).not_to include('<a ')
      expect(result).to include('javascript:alert(1)')
    end
  end
end
