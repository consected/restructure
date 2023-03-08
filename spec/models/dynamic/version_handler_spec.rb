# frozen_string_literal: true

require 'rails_helper'

AlNameGenTest = 'Gen Test ELT'
# Use the activity log player contact phone activity log implementation,
# since it includes the works_with concern

RSpec.describe 'Definition versioning', type: :model do
  include ModelSupport
  include PlayerContactSupport

  def al_name
    AlNameGenTest
  end

  before :context do
    SetupHelper.setup_al_gen_tests AlNameGenTest, 'elt', 'player_contact'
  end

  before :each do
    create_admin
    create_user
    setup_access :player_contacts
    setup_access :activity_log__player_contact_phones
    @player_contact = create_item(data: rand(10_000_000_000_000_000), rank: 10)

    @activity_log = al = ActivityLog.active.where(name: al_name).first
    @working_data = '(111)222-3333 ext 7654321'

    raise "Activity Log #{al_name} not set up" if @activity_log.nil?

    @activity_log.current_admin = @admin

    @activity_log.extra_log_types = <<~END_DEF
      step_1:
        label: Step 1 v1
        fields:
          - select_call_direction
          - select_who

      step_2:
        label: Step 2 v1
        fields:
          - select_call_direction
          - select_who
    END_DEF

    @activity_log.save!
    @orig_num_versions = @activity_log.all_versions.length
    c1 = @activity_log.option_configs[0]
    c2 = @activity_log.option_configs[1]
    setup_access al.resource_name, resource_type: :table, user: @user
    setup_access c1.resource_name, resource_type: :activity_log_type, user: @user
    setup_access c2.resource_name, resource_type: :activity_log_type, user: @user

    @player_contact.current_user = @user
  end

  def latest_history_item
    qres = Admin::MigrationGenerator.connection.execute <<~END_SQL
      select * from activity_log_history
      order by id desc
      limit 1
    END_SQL

    qres.first.to_h
  end

  def all_versions
    @activity_log.all_versions
  end

  it 'manages definition versions' do
    v1 = latest_history_item
    at_1 = DateTime.now
    expect(all_versions.length).to eq @orig_num_versions
    sleep 2

    @activity_log.extra_log_types = <<~END_DEF
      step_1:
        label: Step 1 v2
        fields:
          - select_call_direction
          - select_who

      step_2:
        label: Step 2 v2
        fields:
          - select_call_direction
          - select_who
    END_DEF

    @activity_log.save!
    v2 = latest_history_item
    at_2 = DateTime.now
    expect(all_versions.length).to eq(@orig_num_versions + 1)

    c1 = @activity_log.option_configs[0]
    expect(c1.label).to eq 'Step 1 v2'

    c1 = @activity_log.option_configs[1]
    expect(c1.label).to eq 'Step 2 v2'

    sleep 2
    expect(all_versions.length).to eq(@orig_num_versions + 1)

    # Save an instance using v2
    @player_contact.current_user = @user
    al_v2 = @player_contact.activity_log__player_contact_elts.create!(select_call_direction: 'from staff',
                                                                      extra_log_type: 'step_2',
                                                                      select_who: 'abc',
                                                                      master: @player_contact.master)

    new_al = ActivityLog::PlayerContactElt.find(al_v2.id)
    c1 = new_al.versioned_definition.option_configs[1]
    expect(c1.label).to eq 'Step 2 v2'

    sleep 2

    ##### Add a new version

    @activity_log.extra_log_types = <<~END_DEF
      step_1:
        label: Step 1 v3
        fields:
          - select_call_direction
          - select_who

      step_2:
        label: Step 2 v3
        fields:
          - select_call_direction
          - select_who

      step_3:
        label: Step 3 v3
        fields:
          - select_call_direction
          - select_who
    END_DEF

    @activity_log.save!
    v3 = latest_history_item
    at_3 = DateTime.now

    c1 = @activity_log.option_configs[0]
    expect(c1.label).to eq 'Step 1 v3'

    c1 = @activity_log.option_configs[1]
    expect(c1.label).to eq 'Step 2 v3'

    c1 = @activity_log.option_configs[2]
    expect(c1.label).to eq 'Step 3 v3'
    sleep 2

    # al_v3 = @player_contact.activity_log__player_contact_elts.create!(select_call_direction: 'from staff',
    #                                                                   extra_log_type: 'step_3',
    #                                                                   select_who: 'abc')

    expect(all_versions.length).to eq(@orig_num_versions + 2)

    all_versions
    @activity_log.versioned(at_1)
    expect(@activity_log.versioned(at_1)).to eq all_versions[2]
    expect(@activity_log.versioned(at_2)).to eq all_versions[1]
    expect(@activity_log.versioned(at_3)).to be nil # since it is the current version and this is what is returned

    expect(@activity_log.versioned(DateTime.now + 99.years)).to be nil # simulates *use_def_version_time*

    new_al = ActivityLog::PlayerContactElt.find(al_v2.id)
    c1 = new_al.versioned_definition.option_configs[1]
    expect(c1.label).to eq 'Step 2 v2'

    ##### Force use of the current version

    sleep 2

    @activity_log.extra_log_types = <<~END_DEF
      _configurations:
        use_current_version: true

      step_1:
        label: Step 1 v4
        fields:
          - select_call_direction
          - select_who

      step_2:
        label: Step 2 v4
        fields:
          - select_call_direction
          - select_who

      step_3:
        label: Step 3 v4
        fields:
          - select_call_direction
          - select_who
    END_DEF

    @activity_log.save!
    v4 = latest_history_item
    at_4 = DateTime.now

    c1 = @activity_log.option_configs[0]
    expect(c1.label).to eq 'Step 1 v4'

    c1 = @activity_log.option_configs[1]
    expect(c1.label).to eq 'Step 2 v4'

    c1 = @activity_log.option_configs[2]
    expect(c1.label).to eq 'Step 3 v4'
    sleep 2

    # al_v3 = @player_contact.activity_log__player_contact_elts.create!(select_call_direction: 'from staff',
    #                                                                   extra_log_type: 'step_3',
    #                                                                   select_who: 'abc')

    expect(all_versions.length).to eq(@orig_num_versions + 3)

    all_versions
    @activity_log.versioned(at_1)
    expect(@activity_log.versioned(at_1)).to eq all_versions[3]
    expect(@activity_log.versioned(at_2)).to eq all_versions[2]
    expect(@activity_log.versioned(at_3)).to be all_versions[1]
    expect(@activity_log.versioned(at_4)).to be nil # since it is the current version and this is what is returned

    # Instance should be using definition v4 - since use_current_version is set
    new_al = ActivityLog::PlayerContactElt.find(al_v2.id)
    c1 = new_al.versioned_definition.option_configs[1]
    expect(c1.label).to eq 'Step 2 v4'

    al_v4 = @player_contact.activity_log__player_contact_elts.create!(select_call_direction: 'from staff',
                                                                      extra_log_type: 'step_2',
                                                                      select_who: 'abc',
                                                                      master: @player_contact.master)

    c4 = al_v4.versioned_definition.option_configs[1]
    expect(c4.label).to eq 'Step 2 v4'
  end
end
