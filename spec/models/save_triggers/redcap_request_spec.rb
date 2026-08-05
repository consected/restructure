require 'rails_helper'

# Tests for SaveTriggers::RedcapRequest, covering the import_records and
# survey_link chained save trigger flow, the remove_project_user method
# added for issue #1259 (allowing a save/batch trigger to remove a REDCap
# user's access from a project via the REDCap API), and the import_project_user
# method for adding or updating a user's privileges in a REDCap project via
# a save_trigger or batch_trigger (both share the same RedcapRequest handler).
RSpec.describe SaveTriggers::RedcapRequest, type: :model do
  include ModelSupport
  include ActivityLogSupport

  include Redcap::RedcapSupport

  before :example do
    create_admin
    @projects = setup_redcap_project_admin_configs
    @project = @projects.find { |h| h[:name] == 'save_trigger' }
  end

  before :example do
    SetupHelper.setup_al_player_contact_phones
    res = SetupHelper.setup_al_gen_tests 'Test Pull External', 'test_pull_external', 'player_contact'
    create_user
    @master = create_master
    @player_contact = @master.player_contacts.create! data: '(617)123-1234 b', rec_type: :phone, rank: 10
    @al = create_al_for_resource_name(res.resource_name, master: @master)
    expect(@al.master_id).to eq @master.id
    setup_access @al.resource_name, resource_type: :activity_log_type, access: :create, user: @user
  end

  it 'pushes data to Redcap' do
    # SetupHelper.get_webmock_responses
    # WebMock.allow_net_connect!

    lead_email = 'phil-test12@consected.com'

    instrument = 'research_form'
    record_id = -1
    study_id = 9_999_000
    project_name = @project[:name]
    study = @project[:study] || Redcap::RedcapSupport::DefaultStudy

    config = {
      this2: {
        study:,
        project_name:,
        local_data: 'import_response',
        method: 'import_records',
        post_data: {
          data: [{ record_id:, study_id: }],
          force_auto_number: true
        },
        success_if: {
          all: {
            this: {
              save_trigger_results: {
                element: 'import_response',
                condition: '<> ARRAY_LENGTH',
                value: 0
              }
            }
          }
        }
      },
      this1: {
        study:,
        project_name:,
        local_data: 'link_response',
        method: 'survey_link',
        data_field: 'notes',
        data_field_format: 'json',
        post_data: {
          instrument:,
          record_id: '{{save_trigger_results.import_response.first}}'
        }
      }

    }

    puts String.yaml_dump(config)

    @trigger = SaveTriggers::RedcapRequest.new(config, @al)
    @trigger.perform

    expect(@al.save_trigger_results['import_response']).to be_a(Array)
    expect(@al.save_trigger_results['import_response'].first.to_i).not_to eq 0
    expect(@al.save_trigger_results['import_response_success_if_res']).to be true
    expect(@al.save_trigger_results['import_response_http_response_code']).to eq 200

    expect(@al.notes).to be_present
    dnotes = JSON.parse(@al.notes)
    expect(dnotes).to be_a String
  end

  it 'removes a project user via the redcap_request trigger' do
    project_name = @project[:name]
    study = @project[:study] || Redcap::RedcapSupport::DefaultStudy

    config = {
      this1: {
        study:,
        project_name:,
        local_data: 'remove_user_response',
        method: 'remove_project_user',
        post_data: {
          username: 'd20'
        }
      }
    }

    @trigger = SaveTriggers::RedcapRequest.new(config, @al)
    @trigger.perform

    expect(@al.save_trigger_results['remove_user_response']).to eq 1
    expect(@al.save_trigger_results['remove_user_response_http_response_code']).to eq 200

    audit = Redcap::ClientRequest.order(created_at: :desc).first
    expect(audit.action).to eq 'user'
    expect(audit.result['api_action']).to eq 'delete'
  end

  it 'refreshes the project_users cache using an on_complete hook after removing a user' do
    project_name = @project[:name]
    study = @project[:study] || Redcap::RedcapSupport::DefaultStudy

    config = {
      this1: {
        study:,
        project_name:,
        local_data: 'remove_user_response',
        method: 'remove_project_user',
        post_data: {
          username: 'd20'
        },
        on_complete: [
          {
            redcap_request: {
              this1a: {
                study:,
                project_name:,
                local_data: 'refreshed_users_response',
                method: 'project_users',
                post_data: {
                  force_reload: true
                }
              }
            }
          }
        ]
      }
    }

    @trigger = SaveTriggers::RedcapRequest.new(config, @al)
    @trigger.perform

    expect(@al.save_trigger_results['remove_user_response']).to eq 1
    expect(@al.save_trigger_results['refreshed_users_response']).to be_a(Array)
    expect(@al.save_trigger_results['refreshed_users_response_http_response_code']).to eq 200
  end

  it 'imports (adds or updates) a project user via the redcap_request trigger' do
    project_name = @project[:name]
    study = @project[:study] || Redcap::RedcapSupport::DefaultStudy

    user_data = { username: 'd20', expiration: '2036-01-01', record_delete: 1, api_import: 1 }
    stub_request_import_project_user @project[:server_url], @project[:api_key], user_data: user_data

    config = {
      this1: {
        study:,
        project_name:,
        local_data: 'update_project_user_response',
        method: 'import_project_user',
        post_data: {
          username: 'd20',
          expiration: '2036-01-01',
          record_delete: 1,
          api_import: 1
        }
      }
    }

    @trigger = SaveTriggers::RedcapRequest.new(config, @al)
    @trigger.perform

    expect(@al.save_trigger_results['update_project_user_response']).to eq 1
    expect(@al.save_trigger_results['update_project_user_response_http_response_code']).to eq 200

    audit = Redcap::ClientRequest.order(created_at: :desc).first
    expect(audit.action).to eq 'user'
    expect(audit.result['retrieved_from']).to eq 'api'
  end

  it 'refreshes the project_users cache using an on_complete hook after importing a user' do
    project_name = @project[:name]
    study = @project[:study] || Redcap::RedcapSupport::DefaultStudy

    user_data = { username: 'd20', expiration: '2036-01-01', record_delete: 1, api_import: 1 }
    stub_request_import_project_user @project[:server_url], @project[:api_key], user_data: user_data

    config = {
      this1: {
        study:,
        project_name:,
        local_data: 'update_project_user_response',
        method: 'import_project_user',
        post_data: {
          username: 'd20',
          expiration: '2036-01-01',
          record_delete: 1,
          api_import: 1
        },
        on_complete: [
          {
            redcap_request: {
              this1a: {
                study:,
                project_name:,
                local_data: 'refreshed_users_response',
                method: 'project_users',
                post_data: {
                  force_reload: true
                }
              }
            }
          }
        ]
      }
    }

    @trigger = SaveTriggers::RedcapRequest.new(config, @al)
    @trigger.perform

    expect(@al.save_trigger_results['update_project_user_response']).to eq 1
    expect(@al.save_trigger_results['refreshed_users_response']).to be_a(Array)
    expect(@al.save_trigger_results['refreshed_users_response_http_response_code']).to eq 200
  end

  # batch_trigger shares the same SaveTriggers::RedcapRequest handler as save_trigger.
  # The following test verifies that import_project_user works when invoked from a
  # batch_trigger context by calling the trigger handler directly with a batch-style config.
  it 'imports a project user via the batch_trigger redcap_request path' do
    project_name = @project[:name]
    study = @project[:study] || Redcap::RedcapSupport::DefaultStudy

    user_data = { username: 'd20', expiration: '2036-01-01', record_delete: 1, api_import: 1 }
    stub_request_import_project_user @project[:server_url], @project[:api_key], user_data: user_data

    # batch_trigger on_record dispatches to SaveTriggers::RedcapRequest with the same
    # config structure as a save_trigger, so this exercises the identical code path.
    config = [
      {
        this1: {
          study:,
          project_name:,
          local_data: 'batch_update_user_response',
          method: 'import_project_user',
          post_data: {
            username: 'd20',
            expiration: '2036-01-01',
            record_delete: 1,
            api_import: 1
          }
        }
      }
    ]

    @trigger = SaveTriggers::RedcapRequest.new(config, @al)
    @trigger.perform

    expect(@al.save_trigger_results['batch_update_user_response']).to eq 1
    expect(@al.save_trigger_results['batch_update_user_response_http_response_code']).to eq 200
  end
end
