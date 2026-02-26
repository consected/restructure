# frozen_string_literal: true

# AdminApiDefinitionsHelper Spec
#
# Tests helper methods for generating API documentation in admin definition panels.
# Verifies that the correct REST API endpoints, curl examples, field definitions,
# save trigger YAML, and report-specific curl/save trigger YAML are generated for
# dynamic models, activity logs, external identifiers, and reports.

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
      expect(curl).to include('{{user_email}}')
      expect(curl).to include('{{api_token}}')
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
    it 'returns empty braces when no fields are available' do
      dm = DynamicModel.active_model_configurations.find { |d| !d.table_or_view_ready? }
      next unless dm

      body = helper.api_sample_json_body(dm)
      expect(body).to eq('{}')
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
      expect(result).to include('{{user_email}}')
      expect(result).to include('{{api_token}}')
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
      def respond_to?(m, *) = %i[table_columns table_or_view_ready?].include?(m) || super
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
