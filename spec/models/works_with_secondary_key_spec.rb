# frozen_string_literal: true

require 'rails_helper'

# Use the activity log player contact phone activity log implementation,
# since it includes the works_with concern

RSpec.describe 'Works With handler', type: :model do
  include ModelSupport
  include PlayerContactSupport

  before :all do
    SetupHelper.setup_al_gen_tests 'Works With SK Test', 'works_with_sk', 'player_contact'
    @aldef = ActivityLog.active.find_by(name: 'Works With SK Test', process_name: 'works_with_sk')
    @al_class = @aldef.implementation_class
  end

  before :example do
    create_user
    # Create a random player contact item
    create_item(data: rand(10_000_000_000_000_000), rank: 10, rec_type: 'phone')

    primary_config = @aldef.option_configs(force: true).find { |config| config.name.to_s == 'primary' }
    setup_access @aldef.resource_name.to_sym, resource_type: :table, access: :create, user: @user
    setup_access primary_config.resource_name.to_sym, resource_type: :activity_log_type, access: :create, user: @user
  end

  it 'matches underlying items based on a secondary_key field' do
    # Attempt to create a phone log against the player contact item.
    # Initially, it has not been given the actual reference to the player contact item, or a master ID, so it fails
    # Later, we match with the secondary key (phone number), at which point the assignment should work
    data = @player_contact.data
    al = @al_class.new(select_call_direction: 'from player', select_who: 'user', data: data)
    expect(data).not_to be_blank
    expect(al.data).not_to be_blank

    expect { al.save }.to raise_error FphsException
    al.match_with_parent_secondary_key current_user: @user
    expect(al.save).to be true
  end

  it 'finds an activity log with a secondary key' do
    @player_contact.current_user = @user
    skval = @player_contact.data

    @al_class.definition.configurations = { secondary_key: 'data' }
    al = @player_contact.send(@aldef.resource_name).create!(select_call_direction: 'from player', select_who: 'user', data: skval, master: @player_contact.master)

    expect(al.data).to eq skval
    expect(al.id).not_to be nil

    # Check it is properly persisted
    expect(@al_class.find_by(data: skval).id).to eq al.id

    found_al = @al_class.find_by_id_or_secondary_key(al.id)
    expect(found_al.id).to eq al.id
    found_al = @al_class.find_by_id_or_secondary_key(skval)
    expect(found_al.id).to eq al.id
  end
end
