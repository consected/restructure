require 'rails_helper'

# Use the activity log player contact phone activity log implementation,
# since it includes the works_with concern

RSpec.describe 'Works With handler', type: :model do

  include ModelSupport
  include PlayerContactSupport

  before :all do
    seed_database
    ::ActivityLog.define_models
    create_user
    create_item(data: rand(10000000000000000), rank: 10)
  end

  it "matches underlying items based on a secondary_key field" do

    data = @player_contact.data

    al = ActivityLog::PlayerContactPhone.new(select_call_direction: 'from player', select_who: 'user', data: data)

    res = al.save rescue nil
    expect(res).to be nil

    al.match_with_parent_secondary_key current_user: @user
    expect(al.save).to be true

  end


end
