# frozen_string_literal: true

# AdminApiDefinitionsHelper Spec
#
# Tests helper methods for generating API documentation in admin definition panels.
# Verifies that the correct REST API endpoints, curl examples, field definitions,
# save trigger YAML, and report-specific curl/save trigger YAML are generated for
# dynamic models, activity logs, external identifiers, reports, and standard master
# record models (Admin::MasterRecord - issue #1183).
#
# Issue #1183: clicking the API tab for a non-masters entry in /admin/master_records
# raised "undefined method 'full_item_type_name' for an instance of Admin::MasterRecord"
# because the generic api_panel partial (and AdminApiDefinitionsHelper#api_params_key)
# called full_item_type_name which was missing from Admin::MasterRecord. These specs
# verify that all helper methods work correctly with Admin::MasterRecord instances.

require 'rails_helper'

RSpec.describe AdminApiDefinitionsHelper, type: :helper do
  include ModelSupport

  before(:all) do
    SetupHelper.feature_setup
  end

  describe '#api_base_path' do
    it 'generates a master-nested path for a dynamic model with foreign key' do
      dm = DynamicModel.active_model_configurations.find { |d| d.foreign_key_name.present? }
      next unless dm

      path = helper.api_base_path(dm)
      expect(path).to start_with('/masters/{{master_id}}/')
      expect(path).to include('dynamic_model/')
    end

    it 'generates a non-nested path for a dynamic model without foreign key' do
      dm = DynamicModel.active_model_configurations.find { |d| d.foreign_key_name.blank? }
      next unless dm

      path = helper.api_base_path(dm)
      expect(path).not_to include('{master_id}')
      expect(path).to start_with('/dynamic_model/')
    end

    it 'generates a master-nested path for an activity log' do
      al = ActivityLog.active.first
      next unless al

      path = helper.api_base_path(al)
      expect(path).to start_with('/masters/{{master_id}}/')
      expect(path).to include(al.base_route_segments)
    end

    it 'generates a master-nested path for an external identifier' do
      ei = ExternalIdentifier.active.first
      next unless ei

      path = helper.api_base_path(ei)
      expect(path).to start_with('/masters/{{master_id}}/')
      expect(path).to include(ei.base_route_segments)
    end
  end

  describe '#api_master_nested?' do
    it 'returns true for activity logs' do
      al = ActivityLog.active.first
      next unless al

      expect(helper.api_master_nested?(al)).to be true
    end

    it 'returns true for a dynamic model with foreign_key_name present' do
      dm = DynamicModel.active_model_configurations.find { |d| d.foreign_key_name.present? }
      next unless dm

      expect(helper.api_master_nested?(dm)).to be true
    end

    it 'returns false for a dynamic model with blank foreign_key_name' do
      dm = DynamicModel.active_model_configurations.find { |d| d.foreign_key_name.blank? }
      next unless dm

      expect(helper.api_master_nested?(dm)).to be false
    end

    it 'returns true for external identifiers' do
      ei = ExternalIdentifier.active.first
      next unless ei

      expect(helper.api_master_nested?(ei)).to be true
    end
  end

  describe '#api_endpoints' do
    it 'generates Index, Read, Create, Update endpoints' do
      dm = DynamicModel.active_model_configurations.first
      next unless dm

      endpoints = helper.api_endpoints(dm)
      descriptions = endpoints.map { |e| e[:description] }
      expect(descriptions).to include('Index (list all)')
      expect(descriptions).to include('Read (show one)')
      expect(descriptions).to include('Create')
      expect(descriptions).to include('Update')
    end

    it 'includes extra_log_type routes for activity logs' do
      al = ActivityLog.active.first
      next unless al || al.option_configs_names.blank?

      endpoints = helper.api_endpoints(al)
      methods = endpoints.map { |e| e[:method] }
      expect(methods).to include('GET', 'POST')
      # Should have more than the base 4 endpoints if extra log types exist
      non_standard_names = al.option_configs_names.reject { |n| n.in?(%i[primary blank_log]) }
      expect(endpoints.length).to be > 4 if non_standard_names.any?
    end

    it 'generates exactly 4 endpoints for an external identifier' do
      ei = ExternalIdentifier.active.first
      next unless ei

      endpoints = helper.api_endpoints(ei)
      expect(endpoints.length).to eq(4)
      descriptions = endpoints.map { |e| e[:description] }
      expect(descriptions).to include('Index (list all)', 'Read (show one)', 'Create', 'Update')
    end

    it 'generates correct HTTP methods: GET, GET, POST, PUT' do
      dm = DynamicModel.active_model_configurations.first
      next unless dm

      endpoints = helper.api_endpoints(dm)
      methods = endpoints.map { |e| e[:method] }
      expect(methods).to eq(%w[GET GET POST PUT])
    end
  end

  describe '#api_fields' do
    it 'excludes standard fields like id, created_at, updated_at, master_id' do
      dm = DynamicModel.active_model_configurations.find(&:table_or_view_ready?)
      next unless dm

      fields = helper.api_fields(dm)
      field_names = fields.map { |f| f[:name] }
      expect(field_names).not_to include('id')
      expect(field_names).not_to include('created_at')
      expect(field_names).not_to include('updated_at')
      expect(field_names).not_to include('master_id')
      expect(field_names).not_to include('user_id')
    end

    it 'includes type information for each field' do
      dm = DynamicModel.active_model_configurations.find(&:table_or_view_ready?)
      next unless dm

      fields = helper.api_fields(dm)
      fields.each do |f|
        expect(f[:type]).to be_a(String)
        expect(f[:type]).not_to be_empty
      end
    end

    it 'excludes the contactid standard field' do
      dm = DynamicModel.active_model_configurations.find(&:table_or_view_ready?)
      next unless dm

      fields = helper.api_fields(dm)
      field_names = fields.map { |f| f[:name] }
      expect(field_names).not_to include('contactid')
    end
  end

  describe '#api_fields_list' do
    it 'generates an HTML unordered list of fields' do
      dm = DynamicModel.active_model_configurations.find(&:table_or_view_ready?)
      next unless dm

      html = helper.api_fields_list(dm)
      expect(html).to include('<ul class="api-panel__fields-list">')
      expect(html).to include('</ul>')
      fields = helper.api_fields(dm)
      fields.each do |f|
        expect(html).to include(f[:name])
        expect(html).to include(f[:type])
      end
    end

    it 'returns an empty list when no fields are available' do
      dm = DynamicModel.active_model_configurations.find { |d| !d.table_or_view_ready? }
      next unless dm

      html = helper.api_fields_list(dm)
      expect(html).to include('<ul')
      expect(html).to include('</ul>')
      expect(html).not_to include('<li>')
    end

    it 'excludes standard fields' do
      dm = DynamicModel.active_model_configurations.find(&:table_or_view_ready?)
      next unless dm

      html = helper.api_fields_list(dm)
      AdminApiDefinitionsHelper::STANDARD_FIELDS.each do |sf|
        expect(html).not_to include(">#{sf}<")
      end
    end
  end

  describe '#api_fields_yaml' do
    it 'generates YAML-like field listing' do
      dm = DynamicModel.active_model_configurations.find(&:table_or_view_ready?)
      next unless dm

      yaml = helper.api_fields_yaml(dm)
      expect(yaml).to include('type:')
    end

    it 'returns empty string when no fields are available' do
      dm = DynamicModel.active_model_configurations.find { |d| !d.table_or_view_ready? }
      next unless dm

      yaml = helper.api_fields_yaml(dm)
      expect(yaml).to eq('')
    end

    it 'includes one entry per field with name and type' do
      dm = DynamicModel.active_model_configurations.find(&:table_or_view_ready?)
      next unless dm

      yaml = helper.api_fields_yaml(dm)
      fields = helper.api_fields(dm)
      fields.each do |f|
        expect(yaml).to include("#{f[:name]}:")
        expect(yaml).to include("type: #{f[:type]}")
      end
    end
  end

  describe '#api_sample_json_body' do
    it 'generates a JSON body with placeholder values' do
      dm = DynamicModel.active_model_configurations.find(&:table_or_view_ready?)
      next unless dm

      body = helper.api_sample_json_body(dm)
      expect(body).to start_with('{')
      expect(body).to end_with('}')
    end
  end

  describe '#api_curl_example' do
    it 'generates a curl command with placeholder variables' do
      curl = helper.api_curl_example(method: 'GET', path: '/masters/{{master_id}}/test.json')
      expect(curl).to include('curl -XGET')
      expect(curl).to include('{{base_url}}')
      expect(curl).to include('{{app_type_id}}')
      expect(curl).to include('-H "X-User-Email: {{user_email}}"')
      expect(curl).to include('-H "X-User-Token: {{api_token}}"')
      expect(curl).not_to include('user_email={{user_email}}')
      expect(curl).not_to include('user_token={{api_token}}')
    end

    it 'includes body in POST examples' do
      body = '{ "field": "value" }'
      curl = helper.api_curl_example(method: 'POST', path: '/test.json', body:)
      expect(curl).to include("-d '")
      expect(curl).to include(body)
    end
  end

  describe '#api_save_trigger_example' do
    it 'generates save trigger YAML with pull_external_data' do
      dm = DynamicModel.active_model_configurations.find(&:table_or_view_ready?)
      next unless dm

      yaml = helper.api_save_trigger_example(dm)
      expect(yaml).to include('pull_external_data')
      expect(yaml).to include('get_record')
      expect(yaml).to include('create_record')
      expect(yaml).to include('post_data')
      expect(yaml).to include('{{base_url}}')
    end

    it 'includes the correct base path in trigger URLs' do
      dm = DynamicModel.active_model_configurations.find(&:table_or_view_ready?)
      next unless dm

      yaml = helper.api_save_trigger_example(dm)
      base = helper.api_base_path(dm)
      expect(yaml).to include(base)
    end

    it 'includes _constants section with all placeholder keys' do
      dm = DynamicModel.active_model_configurations.find(&:table_or_view_ready?)
      next unless dm

      yaml = helper.api_save_trigger_example(dm)
      expect(yaml).to include('_constants:')
      expect(yaml).to include('api_user_email: {{user_email}}')
      expect(yaml).to include('api_app_type: {{app_type_id}}')
      expect(yaml).to include('api_shared_secret: {{api_token}}')
      expect(yaml).to include('master_id: {master_id}')
      expect(yaml).to include('item_id: {item_id}')
    end

    it 'includes force_not_editable_save and headers in the create_record block' do
      dm = DynamicModel.active_model_configurations.find(&:table_or_view_ready?)
      next unless dm

      yaml = helper.api_save_trigger_example(dm)
      expect(yaml).to include('force_not_editable_save: true')
      expect(yaml).to include("'Content-Type': 'application/json'")
      expect(yaml).to include("'X-User-Email': '{{constants.api_user_email}}'")
      expect(yaml).to include("'X-User-Token': '{{constants.api_shared_secret}}'")
      expect(yaml).not_to include('&user_email={{constants.api_user_email}}')
      expect(yaml).not_to include('&user_token={{constants.api_shared_secret}}')
    end

    it 'explicitly sets method: post on the create_record action' do
      # Without an explicit method, SaveTriggers::PullExternalData defaults to 'get',
      # which would break the rendered create_record example.
      dm = DynamicModel.active_model_configurations.find(&:table_or_view_ready?)
      next unless dm

      yaml = helper.api_save_trigger_example(dm)
      expect(yaml).to match(/create_record:\s*\n(?:\s+(?!method:).*\n)*\s+method:\s*post\b/)
    end

    it 'includes field-level post_data entries with type-appropriate values' do
      dm = DynamicModel.active_model_configurations.find(&:table_or_view_ready?)
      next unless dm

      yaml = helper.api_save_trigger_example(dm)
      fields = helper.api_fields(dm)
      fields.each do |f|
        expect(yaml).to include("#{f[:name]}:")
      end
    end

    it 'nests post_data fields under the controller params key' do
      dm = DynamicModel.active_model_configurations.find(&:table_or_view_ready?)
      next unless dm

      yaml = helper.api_save_trigger_example(dm)
      key = helper.api_params_key(dm)
      # post_data block must include the wrapping key, followed by field lines
      # indented one more level beneath it.
      expect(yaml).to match(/post_data:\s*\n\s+#{Regexp.escape(key)}:\s*\n/)
    end

    it 'includes embedded_item placeholder in the post_data for activity logs' do
      al = ActivityLog.active.find { |a| a.respond_to?(:table_or_view_ready?) && a.table_or_view_ready? }
      next unless al

      yaml = helper.api_save_trigger_example(al)
      key = helper.api_params_key(al)
      # The embedded_item: {} line must appear nested under the params key in post_data.
      expect(yaml).to match(/#{Regexp.escape(key)}:\s*\n(?:\s+\S.*\n)*\s+embedded_item:\s*\{\}/)
    end

    it 'does not include embedded_item for dynamic models or external identifiers' do
      [DynamicModel.active_model_configurations.find(&:table_or_view_ready?),
       ExternalIdentifier.active.find { |e| e.respond_to?(:table_or_view_ready?) && e.table_or_view_ready? }].compact.each do |defn|
        yaml = helper.api_save_trigger_example(defn)
        expect(yaml).not_to include('embedded_item')
      end
    end
  end

  describe '#api_fields' do
    it 'returns empty array when table is not ready' do
      dm = DynamicModel.active_model_configurations.find { |d| !d.table_or_view_ready? }
      next unless dm

      fields = helper.api_fields(dm)
      expect(fields).to eq([])
    end
  end

  describe '#api_sample_json_body' do
    it 'returns a wrapped empty object when no fields are available' do
      dm = DynamicModel.active_model_configurations.find { |d| !d.table_or_view_ready? }
      next unless dm

      body = helper.api_sample_json_body(dm)
      key = helper.api_params_key(dm)
      expect(body).to eq("{\n  \"#{key}\": {}\n}")
    end

    it 'includes type-appropriate placeholders for each column type' do
      dm = DynamicModel.active_model_configurations.find(&:table_or_view_ready?)
      next unless dm

      body = helper.api_sample_json_body(dm)
      # Should be valid JSON-like structure
      expect(body).to start_with('{')
      expect(body).to end_with('}')
      # Should contain field names from the table
      fields = helper.api_fields(dm)
      fields.each do |f|
        expect(body).to include("\"#{f[:name]}\"")
      end
    end

    it 'wraps fields under the controller params key' do
      dm = DynamicModel.active_model_configurations.find(&:table_or_view_ready?)
      next unless dm

      body = helper.api_sample_json_body(dm)
      key = helper.api_params_key(dm)
      parsed = JSON.parse(body)
      expect(parsed.keys).to eq([key])
      fields = helper.api_fields(dm)
      fields.each do |f|
        expect(parsed[key]).to have_key(f[:name])
      end
    end

    it 'wraps fields under the params key for activity logs' do
      al = ActivityLog.active.find { |a| a.respond_to?(:table_or_view_ready?) && a.table_or_view_ready? }
      next unless al

      body = helper.api_sample_json_body(al)
      key = helper.api_params_key(al)
      parsed = JSON.parse(body)
      expect(parsed.keys).to eq([key])
      expect(key).to start_with('activity_log_')
      expect(key).not_to include('__')
    end

    it 'includes an embedded_item placeholder for activity logs so admins can see where to put nested item data' do
      al = ActivityLog.active.find { |a| a.respond_to?(:table_or_view_ready?) && a.table_or_view_ready? }
      next unless al

      body = helper.api_sample_json_body(al)
      key = helper.api_params_key(al)
      parsed = JSON.parse(body)
      expect(parsed[key]).to have_key('embedded_item')
      expect(parsed[key]['embedded_item']).to eq({})
    end

    it 'does not include embedded_item for dynamic models' do
      dm = DynamicModel.active_model_configurations.find(&:table_or_view_ready?)
      next unless dm

      body = helper.api_sample_json_body(dm)
      parsed = JSON.parse(body)
      expect(parsed[helper.api_params_key(dm)]).not_to have_key('embedded_item')
    end

    it 'does not include embedded_item for external identifiers' do
      ei = ExternalIdentifier.active.find { |e| e.respond_to?(:table_or_view_ready?) && e.table_or_view_ready? }
      next unless ei

      body = helper.api_sample_json_body(ei)
      parsed = JSON.parse(body)
      expect(parsed[helper.api_params_key(ei)]).not_to have_key('embedded_item')
    end

    it 'wraps fields under the params key for external identifiers' do
      ei = ExternalIdentifier.active.find { |e| e.respond_to?(:table_or_view_ready?) && e.table_or_view_ready? }
      next unless ei

      body = helper.api_sample_json_body(ei)
      key = helper.api_params_key(ei)
      parsed = JSON.parse(body)
      expect(parsed.keys).to eq([key])
      expect(key).not_to include('__')
      expect(key).to eq(ei.implementation_model_name)
    end
  end

  describe '#api_params_key' do
    it 'collapses double underscores to a single underscore for dynamic models' do
      dm = DynamicModel.active_model_configurations.first
      next unless dm

      key = helper.api_params_key(dm)
      expect(key).not_to include('__')
      expect(key).to start_with('dynamic_model_')
    end

    it 'collapses double underscores to a single underscore for activity logs' do
      al = ActivityLog.active.first
      next unless al

      key = helper.api_params_key(al)
      expect(key).not_to include('__')
      expect(key).to start_with('activity_log_')
    end

    it 'returns the singular table name for external identifiers' do
      ei = ExternalIdentifier.active.first
      next unless ei

      key = helper.api_params_key(ei)
      expect(key).not_to include('__')
      expect(key).to eq(ei.implementation_model_name)
    end

    it 'returns the singular table name for Admin::MasterRecord (issue #1183)' do
      record = Admin::MasterRecord.find(2) # player_infos
      key = helper.api_params_key(record)
      expect(key).to eq(Settings::DefaultSubjectInfoTableName.singularize)
      expect(key).not_to include('__')
    end

    it 'does not raise an error when called with Admin::MasterRecord (issue #1183)' do
      Admin::MasterRecord.all.each do |record|
        expect { helper.api_params_key(record) }.not_to raise_error
      end
    end
  end

  describe 'Admin::MasterRecord support in API helpers (issue #1183)' do
    let(:player_info_record) { Admin::MasterRecord.find(2) }

    it 'api_base_path generates a master-nested path for player_infos' do
      path = helper.api_base_path(player_info_record)
      expect(path).to start_with('/masters/{{master_id}}/')
      expect(path).to include(Settings::DefaultSubjectInfoTableName)
    end

    it 'api_endpoints generates the 4 standard endpoints for a master record model' do
      endpoints = helper.api_endpoints(player_info_record)
      expect(endpoints.length).to eq(4)
      methods = endpoints.map { |e| e[:method] }
      expect(methods).to eq(%w[GET GET POST PUT])
    end

    it 'api_fields excludes standard fields for a master record model' do
      fields = helper.api_fields(player_info_record)
      field_names = fields.map { |f| f[:name] }
      expect(field_names).not_to include('id', 'created_at', 'updated_at', 'master_id')
      expect(fields).to be_an Array
    end

    it 'api_sample_json_body does not raise an error for Admin::MasterRecord' do
      expect { helper.api_sample_json_body(player_info_record) }.not_to raise_error
    end

    it 'api_sample_json_body wraps fields under the singular table name key' do
      body = helper.api_sample_json_body(player_info_record)
      key = player_info_record.table_name.singularize
      parsed = JSON.parse(body)
      expect(parsed.keys).to eq([key])
    end

    it 'api_save_trigger_example does not raise an error for Admin::MasterRecord' do
      expect { helper.api_save_trigger_example(player_info_record) }.not_to raise_error
    end

    it 'api_save_trigger_example includes the correct base path for player_infos' do
      yaml = helper.api_save_trigger_example(player_info_record)
      expect(yaml).to include("/masters/{{master_id}}/#{Settings::DefaultSubjectInfoTableName}")
    end
  end

  describe '#api_curl_example' do
    it 'does not include -d flag for GET requests' do
      curl = helper.api_curl_example(method: 'GET', path: '/test.json')
      expect(curl).not_to include("-d '")
    end

    it 'includes -d flag with body for PUT requests' do
      body = '{ "field": "value" }'
      curl = helper.api_curl_example(method: 'PUT', path: '/test/{id}.json', body: body)
      expect(curl).to include("-d '")
      expect(curl).to include(body)
      expect(curl).to include('curl -XPUT')
    end
  end

  describe '#api_endpoints' do
    it 'generates exactly 4 base endpoints for non-activity-log definitions' do
      dm = DynamicModel.active_model_configurations.first
      next unless dm

      endpoints = helper.api_endpoints(dm)
      expect(endpoints.length).to eq(4)
    end

    it 'uses .json format for all endpoint paths' do
      dm = DynamicModel.active_model_configurations.first
      next unless dm

      endpoints = helper.api_endpoints(dm)
      endpoints.each do |ep|
        expect(ep[:path]).to end_with('.json')
      end
    end
  end

  describe '#api_report_curl_example' do
    let(:report_double) { double('Report', alt_resource_name: 'test__api_test_report') }

    it 'generates a curl GET command for the given format' do
      result = helper.api_report_curl_example(report_double, format: 'json', sa: 'last_name=test')
      expect(result).to include('curl -XGET')
      expect(result).to include('/reports/test__api_test_report.json')
      expect(result).to include('{{base_url}}')
      expect(result).to include('{{app_type_id}}')
      expect(result).to include('-H "X-User-Email: {{user_email}}"')
      expect(result).to include('-H "X-User-Token: {{api_token}}"')
      expect(result).not_to include('user_email={{user_email}}')
      expect(result).not_to include('user_token={{api_token}}')
    end

    it 'uses the provided format extension in the path' do
      csv_result = helper.api_report_curl_example(report_double, format: 'csv', sa: 'q=1')
      txt_result = helper.api_report_curl_example(report_double, format: 'txt', sa: 'q=1')
      expect(csv_result).to include('.csv')
      expect(csv_result).not_to include('.json')
      expect(txt_result).to include('.txt')
      expect(txt_result).not_to include('.json')
    end

    it 'includes the search attributes query string in the output' do
      result = helper.api_report_curl_example(report_double, format: 'json', sa: 'last_name=foo&year=2024')
      expect(result).to include('last_name=foo&year=2024')
    end
  end

  describe '#api_report_save_trigger_example' do
    let(:report_double) { double('Report', alt_resource_name: 'test__api_test_report') }

    it 'generates YAML with pull_external_data get_report structure' do
      yaml = helper.api_report_save_trigger_example(report_double, sa: 'last_name=test')
      expect(yaml).to include('pull_external_data')
      expect(yaml).to include('get_report')
      expect(yaml).to include('format: json')
      expect(yaml).to include('allow_empty_result: false')
    end

    it 'includes the _constants section with all placeholder keys' do
      yaml = helper.api_report_save_trigger_example(report_double, sa: 'q=1')
      expect(yaml).to include('_constants:')
      expect(yaml).to include('api_user_email: {{user_email}}')
      expect(yaml).to include('api_app_type: {{app_type_id}}')
      expect(yaml).to include('api_shared_secret: {{api_token}}')
    end

    it 'includes the report alt_resource_name in the trigger URL' do
      yaml = helper.api_report_save_trigger_example(report_double, sa: 'last_name=test')
      expect(yaml).to include('/reports/test__api_test_report.json')
    end

    it 'includes the search attributes in the trigger URL' do
      yaml = helper.api_report_save_trigger_example(report_double, sa: 'last_name=smith')
      expect(yaml).to include('last_name=smith')
    end

    it 'uses headers for report save trigger authentication' do
      yaml = helper.api_report_save_trigger_example(report_double, sa: 'q=1')
      expect(yaml).to include("'X-User-Email': '{{constants.api_user_email}}'")
      expect(yaml).to include("'X-User-Token': '{{constants.api_shared_secret}}'")
      expect(yaml).not_to include('&user_email={{constants.api_user_email}}')
      expect(yaml).not_to include('&user_token={{constants.api_shared_secret}}')
    end
  end

  describe 'STANDARD_FIELDS constant' do
    it 'contains the expected standard field names' do
      expect(AdminApiDefinitionsHelper::STANDARD_FIELDS).to include('id', 'created_at', 'updated_at', 'master_id', 'user_id')
    end

    it 'includes contactid' do
      expect(AdminApiDefinitionsHelper::STANDARD_FIELDS).to include('contactid')
    end

    it 'is frozen' do
      expect(AdminApiDefinitionsHelper::STANDARD_FIELDS).to be_frozen
    end
  end

  describe '#api_sample_json_body type-specific placeholders' do
    # Lightweight stubs for table_or_view_ready? and table_columns
    FakeColumn = Struct.new(:name, :type)
    FakeDefinition = Struct.new(:ready, :columns) do
      def table_or_view_ready? = ready
      def table_columns = columns
      def full_item_type_name = 'fake_module__fake_thing'

      def respond_to?(m, *)
        %i[table_columns table_or_view_ready? full_item_type_name].include?(m) || super
      end
    end

    def fake_def_with_column(col_name, col_type)
      FakeDefinition.new(true, [FakeColumn.new(col_name, col_type)])
    end

    it 'uses 0 for integer columns' do
      body = helper.api_sample_json_body(fake_def_with_column('count', :integer))
      expect(body).to include('"count": 0')
    end

    it 'uses 0 for bigint columns' do
      body = helper.api_sample_json_body(fake_def_with_column('big_num', :bigint))
      expect(body).to include('"big_num": 0')
    end

    it 'uses 0.0 for float columns' do
      body = helper.api_sample_json_body(fake_def_with_column('score', :float))
      expect(body).to include('"score": 0.0')
    end

    it 'uses 0.0 for decimal columns' do
      body = helper.api_sample_json_body(fake_def_with_column('amount', :decimal))
      expect(body).to include('"amount": 0.0')
    end

    it 'uses false for boolean columns' do
      body = helper.api_sample_json_body(fake_def_with_column('active', :boolean))
      expect(body).to include('"active": false')
    end

    it 'uses YYYY-MM-DD for date columns' do
      body = helper.api_sample_json_body(fake_def_with_column('dob', :date))
      expect(body).to include('"dob": "YYYY-MM-DD"')
    end

    it 'uses YYYY-MM-DDTHH:MM:SS for datetime columns' do
      body = helper.api_sample_json_body(fake_def_with_column('event_at', :datetime))
      expect(body).to include('"event_at": "YYYY-MM-DDTHH:MM:SS"')
    end

    it 'uses empty string for string / text columns' do
      body = helper.api_sample_json_body(fake_def_with_column('notes', :string))
      expect(body).to include('"notes": ""')
    end
  end
end
