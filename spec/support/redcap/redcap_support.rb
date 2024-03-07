module Redcap
  module RedcapSupport
    def setup_redcap_project_admin_configs(mocks: true)
      setup_file_store

      projects = redcap_project_configs(mocks:)

      Redcap::ProjectAdmin.update_all(disabled: true)
      projects.each do |p|
        if mocks
          if p[:name].in?(['metadata'])
            @metadata_project = p
            stub_request_repeat_instrument_field_project p[:server_url], p[:api_key]
            stub_request_repeat_instrument_field_metadata p[:server_url], p[:api_key]
          else
            stub_request_project p[:server_url], p[:api_key]
            stub_request_metadata p[:server_url], p[:api_key]
          end
          stub_request_project_users p[:server_url], p[:api_key]
          stub_request_instruments p[:server_url], p[:api_key]
        end

        Redcap::ProjectAdmin.create! current_admin: @admin,
                                     study: 'Q2',
                                     name: p[:name],
                                     api_key: p[:api_key],
                                     server_url: p[:server_url]
      end

      expect(Redcap::ProjectAdmin.active.count).to eq 2
      projects
    end

    def setup_file_store
      # Create a matching user for the admin
      @app_type = Admin::AppType.active.find_by(name: 'ref-data')
      @user, = create_user nil, '', email: @admin.email, app_type: @app_type
      setup_access 'trackers', user: @user
      setup_access 'nfs_store__manage__containers', user: @user
      setup_access 'nfs_store__manage__stored_files', user: @user
      setup_access 'nfs_store__manage__archived_files', user: @user
      add_user_to_role Settings.admin_nfs_role, for_user: @user
      add_user_to_role 'admin', for_user: @user
    end

    def reset_mocks
      WebMock.reset!
      redcap_project_configs.each do |project|
        stub_request_project project[:server_url], project[:api_key]
        stub_request_metadata project[:server_url], project[:api_key]
        stub_request_records project[:server_url], project[:api_key]
        stub_request_project_users project[:server_url], project[:api_key]
        stub_request_instruments project[:server_url], project[:api_key]
      end
    end

    def server_url(type)
      @project[:server_url] + "?v=get#{type}"
    end

    def server_url_2(type)
      @metadata_project[:server_url] + "?v=get#{type}"
    end

    def mock_limited_requests
      stub_request_project @project[:server_url], @project[:api_key]
      stub_request_project_users @project[:server_url], @project[:api_key]
      stub_request_instruments @project[:server_url], @project[:api_key]

      stub_request_limited_metadata @project[:server_url], @project[:api_key]
      stub_request_records @project[:server_url], @project[:api_key], 'limited_fields'
    end

    def mock_full_requests
      stub_request_full_project server_url('full'), @project[:api_key]
      stub_request_full_metadata server_url('full'), @project[:api_key]
      stub_request_full_records server_url('full'), @project[:api_key]
      stub_request_full_project_users server_url('full'), @project[:api_key]
      stub_request_full_instruments server_url('full'), @project[:api_key]
    end

    def mock_file_field_requests
      stub_request_file_field_project server_url('file_field'), @project[:api_key]
      stub_request_file_field_metadata server_url('file_field'), @project[:api_key]
      stub_request_file_field_records server_url('file_field'), @project[:api_key]
      stub_request_file server_url('file_field'), @project[:api_key]
      stub_request_project_xml server_url('file_field'), @project[:api_key]
      stub_request_project_users server_url('file_field'), @project[:api_key]
      stub_request_instruments server_url('file_field'), @project[:api_key]
    end

    def mock_repeat_instrument_field_requests
      stub_request_repeat_instrument_field_project server_url_2('repeat_instrument'), @metadata_project[:api_key]
      stub_request_repeat_instrument_field_metadata server_url_2('repeat_instrument'), @metadata_project[:api_key]
      stub_request_repeat_instrument_field_records server_url_2('repeat_instrument'), @metadata_project[:api_key]
      stub_request_project_users server_url_2('repeat_instrument'), @metadata_project[:api_key]
      stub_request_instruments server_url_2('repeat_instrument'), @metadata_project[:api_key]
    end

    # Get project configurations from encrypted credential storage
    def redcap_project_configs(mocks: true, force_reload: false)
      return @redcap_project_configs if @redcap_project_configs && !force_reload

      rcconf = Rails.application.credentials.redcap
      return unless rcconf

      @redcap_project_configs = rcconf[:projects]

      reset_mocks if mocks

      @redcap_project_configs
    end

    def stub_request_project(server_url, api_key)
      stub_request(:post, server_url)
        .with(
          body: { 'content' => 'project', 'format' => 'json', 'token' => api_key }

        )
        .to_return(status: 200, body: project_admin_sample_response, headers: {})
    end

    def stub_request_metadata(server_url, api_key)
      stub_request(:post, server_url)
        .with(
          body: { 'content' => 'metadata', 'fields' => nil, 'format' => 'json', 'token' => api_key }

        )
        .to_return(status: 200, body: metadata_sample_response, headers: {})
    end

    def stub_request_records(server_url, api_key, type = 'narrow')
      stub_request(:post, server_url)
        .with(
          body: {
            'token' => api_key,
            'content' => 'record',
            'format' => 'json'

          }
        )
        .to_return(status: 200, body: data_sample_response(type), headers: {})

      type = if type
               "#{type}-survey-fields"
             else
               'survey-fields'
             end

      stub_request(:post, server_url)
        .with(
          body: {
            'token' => api_key,
            'content' => 'record',
            'format' => 'json',
            'exportSurveyFields' => 'true'
          }
        )
        .to_return(status: 200, body: data_sample_response(type), headers: {})
    end

    def stub_request_limited_metadata(server_url, api_key)
      stub_request(:post, server_url)
        .with(
          body: {
            'content' => 'metadata',
            'fields' => nil,
            'format' => 'json',
            'token' => api_key
          }

        )
        .to_return(status: 200, body: metadata_limited_response, headers: {})
    end

    def stub_request_full_project(server_url, api_key)
      stub_request(:post, server_url)
        .with(
          body: { 'content' => 'project', 'format' => 'json', 'token' => api_key }

        )
        .to_return(status: 200, body: project_admin_sample_response, headers: {})
    end

    def stub_request_full_metadata(server_url, api_key)
      stub_request(:post, server_url)
        .with(
          body: {
            'content' => 'metadata',
            'fields' => nil,
            'format' => 'json',
            'token' => api_key
          }

        )
        .to_return(status: 200, body: metadata_full_response, headers: {})
    end

    def stub_request_full_project_users(server_url, api_key)
      stub_request(:post, server_url)
        .with(
          body: {
            'content' => 'user',
            'format' => 'json',
            'token' => api_key
          }

        )
        .to_return(status: 200, body: project_users_full_response, headers: {})
    end

    def stub_request_project_users(server_url, api_key)
      stub_request(:post, server_url)
        .with(
          body: {
            'content' => 'user',
            'format' => 'json',
            'token' => api_key
          }

        )
        .to_return(status: 200, body: project_users_full_response, headers: {})
    end

    def stub_request_instruments(server_url, api_key)
      stub_request(:post, server_url)
        .with(
          body: {
            'content' => 'instrument',
            'format' => 'json',
            'token' => api_key
          }

        )
        .to_return(status: 200, body: project_instruments_full_response, headers: {})
    end

    alias stub_request_full_instruments stub_request_instruments

    def stub_request_project_users_updated(server_url, api_key)
      stub_request(:post, server_url)
        .with(
          body: {
            'content' => 'user',
            'format' => 'json',
            'token' => api_key
          }

        )
        .to_return(status: 200, body: project_users_updated_response, headers: {})
    end

    def stub_request_project_users_deleted(server_url, api_key)
      stub_request(:post, server_url)
        .with(
          body: {
            'content' => 'user',
            'format' => 'json',
            'token' => api_key
          }

        )
        .to_return(status: 200, body: project_users_deleted_response, headers: {})
    end

    def stub_request_full_records(server_url, api_key)
      stub_request(:post, server_url)
        .with(
          body: {
            'token' => api_key,
            'content' => 'record',
            'format' => 'json'

          }
        )
        .to_return(status: 200, body: data_full_response, headers: {})

      stub_request(:post, server_url)
        .with(
          body: {
            'token' => api_key,
            'content' => 'record',
            'format' => 'json',
            'exportSurveyFields' => 'true'

          }
        )
        .to_return(status: 200, body: data_full_response('-survey-fields'), headers: {})
    end

    def stub_request_file_field_project(server_url, api_key)
      stub_request(:post, server_url)
        .with(
          body: { 'content' => 'project', 'format' => 'json', 'token' => api_key }
        )
        .to_return(status: 200, body: project_admin_sample_response, headers: {})
    end

    def stub_request_file_field_metadata(server_url, api_key)
      stub_request(:post, server_url)
        .with(
          body: { 'content' => 'metadata', 'fields' => nil, 'format' => 'json', 'token' => api_key }
        )
        .to_return(status: 200, body: metadata_file_field_response, headers: {})
    end

    def stub_request_file_field_records(server_url, api_key)
      stub_request(:post, server_url)
        .with(
          body: {
            'token' => api_key,
            'content' => 'record',
            'format' => 'json'
          }
        )
        .to_return(status: 200, body: data_file_field_response, headers: {})

      stub_request(:post, server_url)
        .with(
          body: {
            'token' => api_key,
            'content' => 'record',
            'format' => 'json',
            'exportSurveyFields' => 'true'
          }
        )
        .to_return(status: 200, body: data_file_field_response('-survey-fields'), headers: {})
    end

    def stub_request_file(server_url, api_key, body: nil)
      body ||= Digest::SHA256.hexdigest(rand(1_000_000_000_000).to_s)

      stub_request(:post, server_url)
        .with(
          body: {
            'action' => 'export',
            'content' => 'file',
            'field' => /.+/,
            'format' => 'json',
            'record' => /\d+/,
            'token' => api_key
          }
        )
        .to_return(status: 200, body:, headers: {})
    end

    def stub_request_project_xml(server_url, api_key, body: nil)
      body ||= File.read('spec/fixtures/redcap/q2_demo_project.xml')

      stub_request(:post, server_url)
        .with(
          body: {
            'content' => 'project_xml',
            'exportDataAccessGroups' => 'true',
            'exportSurveyFields' => 'true',
            'format' => 'json',
            'returnFormat' => 'json',
            'returnMetadataOnly' => 'false',
            'token' => api_key
          }
        )
        .to_return(status: 200, body:, headers: {})
    end

    def stub_request_repeat_instrument_field_project(server_url, api_key)
      stub_request(:post, server_url)
        .with(
          body: { 'content' => 'project', 'format' => 'json', 'token' => api_key }
        )
        .to_return(status: 200, body: project_admin_repeat_instrument_response, headers: {})
    end

    def stub_request_repeat_instrument_field_metadata(server_url, api_key)
      stub_request(:post, server_url)
        .with(
          body: { 'content' => 'metadata', 'fields' => nil, 'format' => 'json', 'token' => api_key }
        )
        .to_return(status: 200, body: metadata_repeat_instrument_response, headers: {})
    end

    def stub_request_repeat_instrument_field_records(server_url, api_key)
      stub_request(:post, server_url)
        .with(
          body: {
            'token' => api_key,
            'content' => 'record',
            'format' => 'json'
          }
        )
        .to_return(status: 200, body: data_repeat_instrument_response, headers: {})
    end

    def project_admin_sample_response
      File.read('spec/fixtures/redcap/full_project_info.json')
    end

    def project_admin_repeat_instrument_response
      File.read('spec/fixtures/redcap/repeat_instrument_project_info.json')
    end

    def metadata_sample_response
      File.read('spec/fixtures/redcap/short_metadata_narrow.json')
    end

    def metadata_limited_response
      File.read('spec/fixtures/redcap/limited_metadata.json')
    end

    def metadata_full_response
      File.read('spec/fixtures/redcap/full_metadata.json')
    end

    def metadata_repeat_instrument_response
      File.read('spec/fixtures/redcap/repeat_instrument_metadata.json')
    end

    def project_users_full_response
      File.read('spec/fixtures/redcap/full_project_users.json')
    end

    def project_instruments_full_response
      File.read('spec/fixtures/redcap/full_project_instruments.json')
    end

    def project_users_updated_response
      File.read('spec/fixtures/redcap/full_project_users_updated.json')
    end

    def project_users_deleted_response
      File.read('spec/fixtures/redcap/full_project_users_deleted.json')
    end

    def data_full_response(suffix = nil)
      File.read("spec/fixtures/redcap/full_records#{suffix}.json")
    end

    def metadata_file_field_response
      File.read('spec/fixtures/redcap/file_field_metadata.json')
    end

    def data_file_field_response(suffix = nil)
      File.read("spec/fixtures/redcap/file_field_records#{suffix}.json")
    end

    def data_repeat_instrument_response(suffix = nil)
      File.read("spec/fixtures/redcap/repeat_instrument_records#{suffix}.json")
    end

    #
    # The narrow records only include the fields in the short_metadata_narrow, across two forms.
    # These fields are:
    # record_id dob current_weight smoketime___pnfl smoketime___dnfl smoketime___anfl smoke_start smoke_stop
    # smoke_curr demog_date ncmedrec_add ladder_wealth ladder_comm born_address twelveyrs_address
    # othealth___complete othealth_date sdfsdaf___0 sdfsdaf___1 sdfsdaf___2 rtyrtyrt___0 rtyrtyrt___1 rtyrtyrt___2
    # test_field test_phone i57 f57 dd yes_or_no
    def data_sample_response(type = 'narrow')
      File.read("spec/fixtures/redcap/short_records_#{type}.json")
    end

    #
    # List of field names in the sample response data
    # @return [Array{String}]
    def data_sample_response_fields(type = 'narrow')
      JSON.parse(data_sample_response(type)).first.keys
    end

    #
    # Set up the appropriate dynamic model for the narrow record data.
    # The spec/migrations/20210212065538_create_rc_sample_responses_qoezsq.rb migration
    # handles the creation of the table
    def create_dynamic_model_for_sample_response(survey_fields: nil, disable: nil)
      j = {
        default: {
          db_configs: {
            record_id: { type: 'string' },
            dob: { type: 'date' },
            current_weight: { type: 'decimal' },
            smoketime___pnfl: { type: 'boolean' },
            smoketime___dnfl: { type: 'boolean' },
            smoketime___anfl: { type: 'boolean' },
            smoke_start: { type: 'decimal' },
            smoke_stop: { type: 'decimal' },
            smoke_curr: { type: 'string' },
            demog_date: { type: 'timestamp' },
            ncmedrec_add: { type: 'string' },
            ladder_wealth: { type: 'string' },
            ladder_comm: { type: 'string' },
            born_address: { type: 'string' },
            twelveyrs_address: { type: 'string' },
            othealth___complete: { type: 'boolean' },
            othealth_date: { type: 'timestamp' },
            q2_survey_complete: { type: 'integer' },
            sdfsdaf___0: { type: 'boolean' },
            sdfsdaf___1: { type: 'boolean' },
            sdfsdaf___2: { type: 'boolean' },
            rtyrtyrt___0: { type: 'boolean' },
            rtyrtyrt___1: { type: 'boolean' },
            rtyrtyrt___2: { type: 'boolean' },
            test_field: { type: 'string' },
            test_phone: { type: 'string' },
            i57: { type: 'integer' },
            f57: { type: 'decimal' },
            dd: { type: 'timestamp' },
            yes_or_no: { type: 'boolean' },
            test_complete: { type: 'integer' }
          }
        }
      }

      type = 'narrow'
      tn = 'rc_sample_responses'
      if survey_fields
        j[:default][:db_configs].merge!  test_timestamp: { type: 'timestamp' },
                                         q2_survey_timestamp: { type: 'timestamp' },
                                         redcap_survey_identifier: { type: 'string' }

        type = 'narrow-survey-fields'
        tn = 'rc_sample_sf_responses'
      end

      field_list = data_sample_response_fields(type).dup
      field_list << 'disabled' if disable

      options = YAML.dump j.deep_stringify_keys

      @dynamic_model = DynamicModel.create! current_admin: @admin,
                                            name: @project[:name],
                                            table_name: tn,
                                            primary_key_name: :id,
                                            foreign_key_name: nil,
                                            category: :test,
                                            field_list: field_list.join(' '),
                                            options:
    end

    def setup_file_fields(alt_name = nil)
      mock_file_field_requests

      tn = alt_name || 'redcap_test.test_file_field_recs'

      @project_admin = Redcap::ProjectAdmin.where(name: @project[:name], study: 'Q3', dynamic_model_table: tn).first
      return @project_admin if @project_admin

      @project_admin = Redcap::ProjectAdmin.create! name: @project[:name], server_url: server_url('file_field'), api_key: @project[:api_key], study: 'Q3',
                                                    current_admin: @admin, dynamic_model_table: tn
    end

    def setup_repeat_instrument_fields(alt_name = nil)
      mock_repeat_instrument_field_requests

      tn = alt_name || 'test.test_repinst_field_recs'
      name = @metadata_project[:name]

      @project_admin_metadata = Redcap::ProjectAdmin.where(name:, study: 'Repeat', dynamic_model_table: tn).first
      return @project_admin_metadata if @project_admin_metadata

      @project_admin_metadata = Redcap::ProjectAdmin.create! name:, server_url: server_url_2('repeat_instrument'),
                                                             api_key: @metadata_project[:api_key], study: 'Repeat',
                                                             current_admin: @admin, dynamic_model_table: tn
    end
  end
end
