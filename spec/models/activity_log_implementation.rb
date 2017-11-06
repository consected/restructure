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

    expect(master.activity_log__player_contact_phones).not_to be nil

    expect(al.player_contact).to eq @player_contact
    expect(al.save).to be true
    expect(al.master_id).to eq @player_contact.master_id
    al.reload
    # We expect data to match, based on an automatic sync of related fields
    puts al.inspect
    expect(al.data).to eq data
    expect(al.select_call_direction).to eq 'from player'
    expect(al.select_who).to eq 'user'
    expect(al.user_id).to eq user.id


  end


end
