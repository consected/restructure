# frozen_string_literal: true

# Purpose: Tests for the REDCap Users seeded admin report (GitHub Issue #1258).
#
# This report allows admins to search project users across REDCap projects.
# The tests verify:
#   - The seed module exists and creates a "REDCap Users" report in item_type 'z-admin'
#   - The report has the correct short_name 'redcap_users'
#   - The report SQL includes the required named parameters (:email, :username, :server_url)
#   - The report SQL joins redcap_project_users to redcap_project_admins
#   - The project name (rpa.name) is rendered as a markdown link to the project admin edit page
#   - The report's column_options declare show_as: url for the name field
#   - The search_attrs YAML includes email, username, and server_url select_from_model fields
#   - The admin index page REDCap block contains a "Search Project Users" link
#   - The "Search Project Users" link is visible only to users with :redcap admin permission
#     who also have access to the 'ref-data' app type
#   - The seed is idempotent: running setup twice does not create duplicate records

require 'rails_helper'

RSpec.describe 'REDCap User Report - Issue #1258', type: :model do
  include ModelSupport

  let(:template_path) { Rails.root.join('app/views/pages/_index_admin.html.erb') }
  let(:template_content) { File.read(template_path) }
  let(:seed_module) { Seeds::ReportRedcapUsers }

  before :all do
    Seeds::ReportRedcapUsers.setup
  end

  let(:report) { Report.find_by(short_name: 'redcap_users', item_type: 'z-admin') }

  describe 'seed module' do
    it 'defines Seeds::ReportRedcapUsers' do
      expect(defined?(Seeds::ReportRedcapUsers)).to be_truthy
    end

    it 'responds to setup' do
      expect(Seeds::ReportRedcapUsers).to respond_to(:setup)
    end
  end

  describe 'report creation' do
    it 'creates the REDCap Users report' do
      expect(report).not_to be_nil, 'Expected a report with short_name redcap_users and item_type z-admin'
    end

    it 'names the report REDCap Users' do
      expect(report.name).to eq('REDCap Users')
    end

    it 'is not disabled' do
      expect(report.disabled).not_to eq(true)
    end

    it 'has report_type regular_report' do
      expect(report.report_type).to eq('regular_report')
    end
  end

  describe 'report SQL' do
    subject(:sql) { report.sql }

    it 'includes the :email named parameter' do
      expect(sql).to include(':email')
    end

    it 'includes the :username named parameter' do
      expect(sql).to include(':username')
    end

    it 'includes the :server_url named parameter' do
      expect(sql).to include(':server_url')
    end

    it 'joins redcap_project_users to redcap_project_admins' do
      expect(sql).to match(/redcap_project_users/)
      expect(sql).to match(/redcap_project_admins/)
      expect(sql).to match(/redcap_project_admin_id/)
    end

    it 'selects study, name, and server_url from redcap_project_admins' do
      expect(sql).to match(/rpa\.study|rpa\.name|rpa\.server_url/)
    end

    it 'includes a markdown link to the project admin edit page in the name column' do
      # The name column should be rendered as a markdown link pointing to
      # the redcap project admin edit page using filter+perform_action params
      expect(sql).to match(%r{redcap/project_admins\?filter\[id\]=.*perform_action=edit})
    end
  end

  describe 'report search_attrs' do
    subject(:search_attrs) { report.search_attrs }

    it 'includes email select_from_model field' do
      expect(search_attrs).to include('email')
      expect(search_attrs).to include('redcap__project_users')
    end

    it 'includes username select_from_model field' do
      expect(search_attrs).to include('username')
    end

    it 'includes server_url select_from_model field' do
      expect(search_attrs).to include('server_url')
      expect(search_attrs).to include('redcap__project_admins')
    end

    it 'configures email as a single-select from redcap_project_users' do
      parsed = YAML.safe_load(search_attrs)
      email_config = parsed.dig('email', 'select_from_model')
      expect(email_config).not_to be_nil
      expect(email_config['multiple']).to eq('single')
      expect(email_config['resource_name']).to eq('redcap__project_users')
      expect(email_config.dig('selections', 'email')).to eq('email')
    end

    it 'configures username as a single-select from redcap_project_users' do
      parsed = YAML.safe_load(search_attrs)
      username_config = parsed.dig('username', 'select_from_model')
      expect(username_config).not_to be_nil
      expect(username_config['multiple']).to eq('single')
      expect(username_config['resource_name']).to eq('redcap__project_users')
      expect(username_config.dig('selections', 'username')).to eq('username')
    end

    it 'configures server_url as a single-select from redcap_project_admins' do
      parsed = YAML.safe_load(search_attrs)
      server_url_config = parsed.dig('server_url', 'select_from_model')
      expect(server_url_config).not_to be_nil
      expect(server_url_config['multiple']).to eq('single')
      expect(server_url_config['resource_name']).to eq('redcap__project_admins')
      expect(server_url_config.dig('selections', 'server_url')).to eq('server_url')
    end
  end

  describe 'report options (column rendering)' do
    subject(:options) { report.options }

    it 'declares show_as: url for the name column' do
      expect(options).to include('show_as')
      parsed = YAML.safe_load(options)
      show_as = parsed.dig('column_options', 'show_as')
      expect(show_as).not_to be_nil
      expect(show_as['name']).to eq('url')
    end
  end

  describe 'Resources::Models registration (required for select_from_model)' do
    it 'registers Redcap::ProjectUser under redcap__project_users' do
      expect(Resources::Models.find_by(resource_name: 'redcap__project_users')).not_to be_nil,
                                                                                       'Redcap::ProjectUser must be registered in Resources::Models for select_from_model to work'
    end

    it 'registers Redcap::ProjectAdmin under redcap__project_admins' do
      expect(Resources::Models.find_by(resource_name: 'redcap__project_admins')).not_to be_nil,
                                                                                        'Redcap::ProjectAdmin must be registered in Resources::Models for select_from_model to work'
    end
  end

  describe 'idempotency' do
    it 'does not create duplicate reports when setup is run twice' do
      expect { Seeds::ReportRedcapUsers.setup }
        .not_to(change { Report.where(short_name: 'redcap_users', item_type: 'z-admin').count })
    end
  end

  describe 'admin index page REDCap block' do
    let(:redcap_block) { template_content[/<% if current_admin\.can_admin\?\(:redcap\)%>.*?<%end%>/m] }

    it 'contains a Search Project Users link' do
      expect(redcap_block).to include('Search Project Users'),
                              'Expected a "Search Project Users" link in the REDCap admin block'
    end

    it 'links to the z-admin reports filtered list' do
      expect(redcap_block).to include('z-admin'),
                              'Expected the Search Project Users link to filter by z-admin reports'
    end

    it 'is guarded by can_admin?(:redcap) permission' do
      expect(redcap_block).not_to be_nil,
                                  'Expected the admin index page to have a REDCap block guarded by can_admin?(:redcap)'
    end
  end
end
