# frozen_string_literal: true

require 'rails_helper'

# View spec for XSS vulnerability in page_layouts/_show_row partial (issue #1224).
#
# When @master (an ActiveRecord model with user-editable fields) is used as
# substitution data for col_header and col_footer, the substituted values are
# NOT HTML-escaped before being spliced into the already-safe HTML string via
# `.html_safe`. This allows stored XSS: any user-controlled field referenced by
# a {{tag}} in a page layout column header or footer is rendered verbatim.
#
# The report_defaults path already escapes values with ERB::Util.html_escape,
# but @master data bypasses that protection.
#
# These tests assert the SECURE behaviour (escaped output) and are expected to
# FAIL (red) until the fix is applied.

RSpec.describe 'page_layouts/_show_row XSS in col header/footer substitution', type: :view do
  let(:xss_script_payload) { '<script>alert(1)</script>' }
  let(:xss_img_payload) { '<img src=x onerror=alert(1)>' }

  let(:container) { double('container') }

  before do
    assign(:master_id, 456)
    # Do NOT stub Formatter::Substitution.substitute — we need real substitution
    # to demonstrate the XSS payload flowing through unescaped.

    # Stub markdown_to_html to pass through (adds <p> wrapper via Kramdown in real use,
    # but that is orthogonal to the escaping issue).
    allow(view).to receive(:markdown_to_html) { |text| text.to_s }

    # Stub the error-page partial so it never triggers.
    stub_template 'layouts/_error_page_block.erb' => ''
  end

  # Helper: build a rows structure with col header/footer containing substitution tags,
  # and a simple report so col_url is generated (avoiding the "Not Found" path).
  def rows_with_header_footer(header:, footer:, report_id: 99)
    report_def = { 'id' => report_id }
    [{ 'cols' => [{ 'label' => 'Test', 'header' => header, 'footer' => footer, 'report' => report_def }] }]
  end

  let(:mock_report) do
    instance_double(Report, search_attributes: {})
  end

  before do
    allow(Report).to receive(:find_by_id_or_resource_name).with(99).and_return(mock_report)
  end

  # ---- XSS via col_header with <script> tag ----------------------------

  context 'when @master has a field containing a <script> XSS payload referenced in col_header' do
    before do
      assign(:master, { rank: xss_script_payload })

      render partial: 'page_layouts/show_row',
             locals: {
               rows: rows_with_header_footer(
                 header: 'Welcome {{rank}}',
                 footer: ''
               ),
               container: container
             }
    end

    it 'escapes the <script> tag in the rendered col_header' do
      # The rendered output must NOT contain a literal <script> tag from user data.
      expect(rendered).not_to include(xss_script_payload)
    end

    it 'contains the HTML-escaped version of the payload in the col_header' do
      expect(rendered).to include('&lt;script&gt;alert(1)&lt;/script&gt;')
    end
  end

  # ---- XSS via col_footer with <script> tag ----------------------------

  context 'when @master has a field containing a <script> XSS payload referenced in col_footer' do
    before do
      assign(:master, { rank: xss_script_payload })

      render partial: 'page_layouts/show_row',
             locals: {
               rows: rows_with_header_footer(
                 header: '',
                 footer: 'Goodbye {{rank}}'
               ),
               container: container
             }
    end

    it 'escapes the <script> tag in the rendered col_footer' do
      expect(rendered).not_to include(xss_script_payload)
    end

    it 'contains the HTML-escaped version of the payload in the col_footer' do
      expect(rendered).to include('&lt;script&gt;alert(1)&lt;/script&gt;')
    end
  end

  # ---- XSS via col_header with <img onerror> payload -------------------

  context 'when @master has a field containing an <img onerror> XSS payload referenced in col_header' do
    before do
      assign(:master, { rank: xss_img_payload })

      render partial: 'page_layouts/show_row',
             locals: {
               rows: rows_with_header_footer(
                 header: 'Hello {{rank}}',
                 footer: ''
               ),
               container: container
             }
    end

    it 'escapes the <img> event handler in the rendered col_header' do
      expect(rendered).not_to include(xss_img_payload)
    end

    it 'contains the HTML-escaped version of the img payload' do
      expect(rendered).to include('&lt;img src=x onerror=alert(1)&gt;')
    end
  end

  # ---- report_defaults path remains safe (control test) ----------------

  context 'when report_defaults (not @master) contains an XSS payload' do
    before do
      # No @master assigned — falls through to report_defaults
      assign(:master, nil)

      render partial: 'page_layouts/show_row',
             locals: {
               rows: [{ 'cols' => [{
                 'label' => 'Test',
                 'header' => 'Value: {{first_name}}',
                 'footer' => '',
                 'report' => { 'id' => 99, 'defaults' => { 'first_name' => xss_script_payload } }
               }] }],
               container: container
             }
    end

    it 'escapes the payload coming through report_defaults' do
      expect(rendered).not_to include(xss_script_payload)
    end
  end
end
