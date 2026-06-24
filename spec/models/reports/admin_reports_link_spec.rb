# frozen_string_literal: true

# Purpose: Tests for the Admin Reports link on the admin dashboard page (GitHub Issue #1216).
#
# The admin dashboard has a "Status" block with navigation links. This spec verifies
# that an "Admin Reports" link exists in the Status block, linking to reports filtered
# by item_type 'z-admin'. The link should be guarded by:
#   1. The admin having :reports permission (can_admin?(:reports))
#   2. Active reports of type 'z-admin' existing (Report.active.where(item_type: 'z-admin').exists?)
#
# Tests verify the template content directly (static analysis of ERB), following the
# same pattern used for the User Access Overview link tests
# (spec/models/reports/user_access_overview_spec.rb).

require 'rails_helper'

RSpec.describe 'Admin Reports link on admin index page - Issue #1216' do
  describe 'admin index page Status block' do
    let(:template_path) { Rails.root.join('app/views/pages/_index_admin.html.erb') }
    let(:template_content) { File.read(template_path) }
    let(:admin_reports_line) do
      template_content.lines.find { |line| line.include?("Settings::AdminReportItemTypes['z-admin']") }
    end

    it 'includes an Admin Reports link using the AdminReportItemTypes constant' do
      expect(admin_reports_line).not_to be_nil,
                                        'Expected an Admin Reports link using Settings::AdminReportItemTypes in the admin index page'
    end

    it 'links to reports filtered by item_type z-admin' do
      expect(admin_reports_line).not_to be_nil, 'Admin Reports link not found'
      expect(admin_reports_line).to include('z-admin'),
                                    'Expected the Admin Reports link to filter by item_type z-admin'
    end

    it 'requires :reports admin permission' do
      expect(admin_reports_line).not_to be_nil, 'Admin Reports link not found'
      expect(admin_reports_line).to include('can_admin?(:reports)'),
                                    'Expected the Admin Reports link to require :reports capability'
    end

    it 'checks for existence of active z-admin reports' do
      expect(admin_reports_line).not_to be_nil, 'Admin Reports link not found'
      expect(admin_reports_line).to include("Report.active.where(item_type: 'z-admin')"),
                                    'Expected the Admin Reports link to check for active z-admin reports'
    end

    it 'places the Admin Reports link in the Status block' do
      status_section = template_content[/Status<\/h3>.*?<\/ul>/m]
      expect(status_section).not_to be_nil, 'Could not find Status section in template'
      expect(status_section).to include("Settings::AdminReportItemTypes['z-admin']"),
                                'Expected Admin Reports link to be within the Status block'
    end

    it 'opens the Admin Reports link in a new tab' do
      expect(admin_reports_line).not_to be_nil, 'Admin Reports link not found'
      expect(admin_reports_line).to include("target: '_blank'"),
                                    'Expected the Admin Reports link to open in a new tab'
    end
  end
end
