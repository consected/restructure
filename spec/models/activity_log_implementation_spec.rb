require 'rails_helper'

# Use the activity log player contact phone activity log implementation,
# since it includes the works_with concern

RSpec.describe 'Activity Log implementation', type: :model do

  include ModelSupport
  include PlayerContactSupport

  before :all do
    seed_database
    ::ActivityLog.define_models
    create_user
    setup_access :player_contacts
    create_item(data: rand(10000000000000000), rank: 10)
  end

  it "saves data into an activity log record" do

    data = @player_contact.data

    # Create a second user to ensure that the user attribute is set correctly on saving
    user, _ = create_user
    @player_contact.master.current_user = user
    master = @player_contact.master
    expect(master.current_user).to eq user
    al = @player_contact.activity_log__player_contact_phones.build(select_call_direction: 'from player', select_who: 'user')
    expect(al.master_user).to eq user
    expect(master.activity_log__player_contact_phones).not_to be nil

    expect(al.player_contact).to eq @player_contact
    rn = al.extra_log_type_config.resource_name

    uacs = UserAccessControl.where app_type: @user.app_type, resource_type: :activity_log_type, resource_name: rn
    if uacs.first
      uac = uacs.first
      uac.access = nil
      uac.current_admin = @admin
      uac.save!
    end

    # Validate that the new activity log item can not be accessed without the appropriate access control
    expect{
      al.save
    }.to raise_error FphsException

    if uac
      uac.access = :create
      uac.disabled = false
      uac.save!
    else
      uac = UserAccessControl.create! app_type: @user.app_type, access: :create, resource_type: :activity_log_type, resource_name: rn, current_admin: @admin
    end
    expect(al.save).to be true


    expect(al.master_id).to eq @player_contact.master_id
    al.reload
    # We expect data to match, based on an automatic sync of related fields

    expect(al.data).to eq PlayerContact.format_data(data)
    expect(al.select_call_direction).to eq 'from player'
    expect(al.select_who).to eq 'user'
    expect(al.user_id).to eq user.id


    uac.update! access: nil, current_admin: @admin

    expect(@user.has_access_to? :access, :activity_log_type, rn).to be_falsey

    expect{al.as_json}.to raise_error FphsException

  end


end
