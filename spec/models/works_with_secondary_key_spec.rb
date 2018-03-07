require 'rails_helper'

# Use the activity log player contact phone activity log implementation,
# since it includes the works_with concern

RSpec.describe 'Works With handler', type: :model do

  include ModelSupport
  include PlayerContactSupport

  before :all do
    # Ensure the activity log implementations are in place
    seed_database
    ::ActivityLog.define_models
    create_user
    # Create a random player contact item
    create_item(data: rand(10000000000000000), rank: 10, rec_type: 'phone')

    # UserAccessControl.create! app_type: @user.app_type, access: :create, resource_type: :table, resource_name: ActivityLog::PlayerContactPhone.name.ns_underscore.pluralize, current_admin: @admin
    UserAccessControl.create! app_type: @user.app_type, access: :create, resource_type: :activity_log_type, resource_name: :activity_log__player_contact_phone__primary, current_admin: @admin

  end

  it "matches underlying items based on a secondary_key field" do

    # Attempt to create a phone log against the player contact item.
    # Initially, it has not been given the actual reference to the player contact item, or a master ID, so it fails
    # Later, we match with the secondary key (phone number), at which point the assignment should work
    data = @player_contact.data

    al = ActivityLog::PlayerContactPhone.new(select_call_direction: 'from player', select_who: 'user', data: data)

    res = al.save rescue nil
    expect(res).to be nil

    al.match_with_parent_secondary_key current_user: @user
    expect(al.save).to be true

  end


end
