module Redcap
  module RedcapSupport
    def setup_redcap_project_admin_configs(mocks: true)
      projects = redcap_project_configs

      Redcap::ProjectAdmin.update_all(disabled: true)

      projects.each do |p|
        if mocks
          stub_request_project p[:server_url], p[:api_key]
          stub_request_metadata p[:server_url], p[:api_key]
        end

        Redcap::ProjectAdmin.create! current_admin: @admin,
                                     study: 'Q2',
                                     name: p[:name],
                                     api_key: p[:api_key],
                                     server_url: p[:server_url]
      end

      expect(Redcap::ProjectAdmin.active.count).to eq 1
      projects
    end

    # Get project configurations from encrypted credential storage
    def redcap_project_configs
      return @redcap_project_configs if @redcap_project_configs

      rcconf = Rails.application.credentials.redcap
      return unless rcconf

      @redcap_project_configs = rcconf[:projects]
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

    def stub_request_records(server_url, api_key)
      stub_request(:post, server_url)
        .with(
          body: { 'token' => api_key,
                  'content' => 'record',
                  'format' => 'json',
                  'type' => 'flat',
                  'rawOrLabel' => 'raw',
                  'rawOrLabelHeaders' => 'raw',
                  'exportCheckboxLabel' => 'false',
                  'exportSurveyFields' => 'false',
                  'exportDataAccessGroups' => 'false',
                  'returnFormat' => 'json' }

        )
        .to_return(status: 200, body: data_sample_response, headers: {})
    end

    def project_admin_sample_response
      File.read('spec/fixtures/redcap/full_project_info.json')
    end

    def metadata_sample_response
      File.read('spec/fixtures/redcap/short_metadata.json')
    end

    def data_sample_response
      File.read('spec/fixtures/redcap/short_records.json')
    end
  end
end
