require 'rails_helper'

RSpec.describe SaveTriggers::RedcapRequest, type: :model do
  include ModelSupport
  include ActivityLogSupport

  include Redcap::RedcapSupport

  before :example do
    create_admin
    @projects = setup_redcap_project_admin_configs
    @project = @projects.find {|h| h[:name] == 'save_trigger' }
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
    study_id = 9999000
    project_name = @project[:name]
    study = @project[:study] || Redcap::RedcapSupport::DefaultStudy

    config = {
      this2: {
        study:,
        project_name:,
        local_data: 'import_response',
        method: 'import_records',        
        post_data: {
          data: [{ record_id: , study_id:  }],
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
      },

    }

    puts YAML.dump(JSON.parse(config.to_json))

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

end
