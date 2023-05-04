# frozen_string_literal: true

require 'rails_helper'

AlNameGenTestAlet = 'Gen Test ELT'
# Use the activity log player contact phone activity log implementation,
# since it includes the works_with concern

RSpec.describe 'Activity Log extra types implementation', type: :model do
  def al_name
    AlNameGenTestAlet
  end

  include ModelSupport
  include PlayerContactSupport

  before :context do
    SetupHelper.setup_al_gen_tests AlNameGenTestAlet, 'elt', 'player_contact'
    # seed_database
    # ::ActivityLog.define_models
    # Seeds::ActivityLogPlayerContactPhone.setup
  end

  before :each do
    create_admin
    create_user
    setup_access :player_contacts
    setup_access :activity_log__player_contact_phones
    create_item(data: rand(10_000_000_000_000_000), rank: 10)

    @activity_log = al = ActivityLog.active.where(name: al_name).first

    raise "Activity Log #{al_name} not set up" if al.nil?

    al.extra_log_types = <<EOF
    step_1:
      label: Step 1
      fields:
        - select_call_direction
        - select_who

    step_2:
      label: Step 2
      fields:
        - select_call_direction
        - extra_text

EOF

    al.current_admin = @admin

    al.save!
  end

  it 'saves data into an activity log record' do
    al = @activity_log

    c1 = al.option_configs.first
    expect(c1.label).to eq 'Step 1'
    expect(c1.fields).to eq %w[select_call_direction select_who]

    c2 = al.option_configs[1]
    expect(c2.label).to eq 'Step 2'
    expect(c2.fields).to eq %w[select_call_direction extra_text]

    # Additional field for extra_log_type is expected to be added to the configuration by default
    expect(OptionConfigs::ActivityLogOptions.fields_for_all_in(al)).to eq %w[select_call_direction select_who
                                                                             extra_text]
  end

  it 'prevents user from accessing specific activity log extra log types' do
    al = @activity_log

    resource_name = al.option_configs.first.resource_name

    res = Admin::UserAccessControl.active.where app_type: @user.app_type, resource_type: :activity_log_type,
                                                resource_name: resource_name
    res.first&.update!(current_admin: @admin, disabled: true)

    res = @user.has_access_to? :access, :activity_log_type, resource_name
    expect(res).to be_falsey
    Admin::UserAccessControl.create! app_type: @user.app_type, access: :read, resource_type: :activity_log_type,
                                     resource_name: resource_name, current_admin: @admin

    res = @user.has_access_to? :access, :activity_log_type, resource_name
    expect(res).to be_truthy
  end

  it 'allows a user only to see the presence of an iten, not its content' do
    resource_name = ActivityLog::PlayerContactPhone.definition.option_type_config_for(:primary).resource_name

    setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
    setup_access resource_name, resource_type: :activity_log_type, access: :create, user: @user

    @player_contact.master.current_user = @user
    al = @player_contact.activity_log__player_contact_phones.build(select_call_direction: 'from player',
                                                                   select_who: 'user')
    al.save!
    alid = al.id

    alpcps = @player_contact.activity_log__player_contact_phones.where id: alid

    alpcps.each do |a|
      a.master.current_user = @user
    end

    j = alpcps.to_json

    data = JSON.parse(j).first
    expect(data['id']).to eq alid
    expect(data['select_who']).to eq 'user'

    # Now restrict access to only see its presence
    setup_access resource_name, resource_type: :activity_log_type, access: :see_presence, user: @user

    res = @user.has_access_to? :access, :activity_log_type, alpcps.first.extra_log_type_config.resource_name
    expect(res).to be_falsey

    res = @user.has_access_to? :see_presence, :activity_log_type, alpcps.first.extra_log_type_config.resource_name
    expect(res).to be_truthy

    res = @user.has_access_to? :see_presence_or_access, :activity_log_type,
                               alpcps.first.extra_log_type_config.resource_name
    expect(res).to be_truthy

    alpcps.each do |a|
      a.master.current_user = @user
    end

    j = alpcps.to_json
    data = JSON.parse(j).first
    expect(data['id']).to eq alid

    expect(data['select_who']).to be_nil
  end
end
