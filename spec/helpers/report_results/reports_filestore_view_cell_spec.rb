# frozen_string_literal: true

# ReportsCommonResultCell filestore_view Spec
#
# Tests the cell content rendering for report cells with show_as: filestore_view.
# The filestore_view option wraps file download links in a span with the
# use-secure-view-on-links class to enable the secure file viewer for
# NFS filestore and Redcap file downloads in report results.
#
# Test Coverage:
# - #cell_content_for_filestore_view: Generates HTML with secure view wrapper
#   - Handles markdown format links [label](url)
#   - Returns blank/nil content unchanged
#   - Wraps link in span.use-secure-view-on-links
#   - Does not add target="_blank" (secure viewer handles display)
# - #html_tag: Returns nil for filestore_view (content includes its own wrapper)
#   - Tested for table, list, and base cell classes

require 'rails_helper'

RSpec.describe ReportResults::ReportsCommonResultCell do
  let(:table_name) { 'dynamic_model__test_items' }
  let(:col_name) { 'file_link' }
  let(:col_tag) { nil }
  let(:col_show_as) { 'filestore_view' }
  let(:selection_options) { double('selection_options') }

  def build_cell(content, klass = described_class)
    klass.new(table_name, content, col_name, col_tag, col_show_as, selection_options)
  end

  describe '#cell_content_for_filestore_view' do
    context 'with NFS filestore download links' do
      it 'wraps the link in a span with use-secure-view-on-links class' do
        html = build_cell('[Download File](/nfs_store/downloads/123)').cell_content_for_filestore_view

        expect(html).to include('class="use-secure-view-on-links"')
        expect(html).to include('<a href="/nfs_store/downloads/123"')
        expect(html).to include('>Download File</a>')
        expect(html).to include('<span')
      end

      it 'does not add target="_blank"' do
        html = build_cell('[File](/nfs_store/downloads/456)').cell_content_for_filestore_view

        expect(html).not_to include('target="_blank"')
      end
    end

    context 'with Redcap file download links' do
      it 'wraps the link in a span with use-secure-view-on-links class' do
        url = '/redcap/project_user_requests/dynamic_model__test_rcs/download_field_file/uploaded_file/99'
        html = build_cell("[View Form](#{url})").cell_content_for_filestore_view

        expect(html).to include('class="use-secure-view-on-links"')
        expect(html).to include("href=\"#{url}\"")
        expect(html).to include('>View Form</a>')
      end
    end

    context 'with edge cases' do
      it 'returns blank content unchanged' do
        expect(build_cell('').cell_content_for_filestore_view).to eq('')
      end

      it 'returns nil content as nil' do
        expect(build_cell(nil).cell_content_for_filestore_view).to be_nil
      end
    end
  end

  describe '#view_content' do
    it 'dispatches to cell_content_for_filestore_view' do
      cell = build_cell('[File](/nfs_store/downloads/1)')
      html = cell.view_content

      expect(html).to include('use-secure-view-on-links')
      expect(html).to include('/nfs_store/downloads/1')
    end
  end

  describe '#html_tag' do
    it 'returns nil for filestore_view in the base class' do
      cell = build_cell('content')
      expect(cell.html_tag).to be_nil
    end

    it 'returns nil for filestore_view in ReportsTableResultCell' do
      cell = build_cell('content', ReportResults::ReportsTableResultCell)
      expect(cell.html_tag).to be_nil
    end

    it 'returns nil for filestore_view in ReportsListResultCell' do
      cell = build_cell('content', ReportResults::ReportsListResultCell)
      expect(cell.html_tag).to be_nil
    end
  end
end
