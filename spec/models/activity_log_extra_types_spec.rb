require 'rails_helper'

# Use the activity log player contact phone activity log implementation,
# since it includes the works_with concern

RSpec.describe 'Activity Log extra types implementation', type: :model do

  include ModelSupport
  include PlayerContactSupport

  before :all do
    seed_database
    ::ActivityLog.define_models
    create_admin
    create_user
    setup_access :player_contacts
    setup_access :activity_log__player_contact_phones
    create_item(data: rand(10000000000000000), rank: 10)

    @activity_log = al = ActivityLog.enabled.first

    al.extra_log_types =<<EOF
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

  it "saves data into an activity log record" do

    al = @activity_log

    c1 = al.extra_log_type_configs.first
    expect(c1.label).to eq 'Step 1'
    expect(c1.fields).to eq ['select_call_direction', 'select_who']

    c2 = al.extra_log_type_configs[1]
    expect(c2.label).to eq 'Step 2'
    expect(c2.fields).to eq ['select_call_direction', 'extra_text']


    # Additional field for extra_log_type is expected to be added to the configuration by default
    expect(ExtraLogType.fields_for_all_in al).to eq ['select_call_direction', 'select_who', 'extra_text']

  end

  it "prevents user from accessing specific activity log extra log types" do
    al = @activity_log

    resource_name = al.extra_log_type_configs.first.resource_name

    res = @user.has_access_to? :access, :activity_log_type, resource_name
    expect(res).to be_falsey
    Admin::UserAccessControl.create! app_type: @user.app_type, access: :read, resource_type: :activity_log_type, resource_name: resource_name, current_admin: @admin

    res = @user.has_access_to? :access, :activity_log_type, resource_name
    expect(res).to be_truthy


  end

  it "allows a user only to see the presence of an iten, not its content" do

    al = @activity_log

    resource_name = ActivityLog::PlayerContactPhone.extra_log_type_config_for('primary').resource_name


    uac = Admin::UserAccessControl.where(app_type: @user.app_type, resource_type: :activity_log_type, resource_name: resource_name).first
    unless uac
      uac = Admin::UserAccessControl.new(app_type: @user.app_type, resource_type: :activity_log_type, resource_name: resource_name)
    end

    # First, allow an activity log record to be created
    uac.access = :create
    uac.current_admin = @admin
    uac.save!


    @player_contact.master.current_user = @user
    al = @player_contact.activity_log__player_contact_phones.build(select_call_direction: 'from player', select_who: 'user')
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
    uac.access = :see_presence
    uac.current_admin = @admin
    uac.save!

    res = @user.has_access_to? :access, :activity_log_type, alpcps.first.extra_log_type_config.resource_name
    expect(res).to be_falsey

    res = @user.has_access_to? :see_presence, :activity_log_type, alpcps.first.extra_log_type_config.resource_name
    expect(res).to be_truthy


    res = @user.has_access_to? :see_presence_or_access, :activity_log_type, alpcps.first.extra_log_type_config.resource_name
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
