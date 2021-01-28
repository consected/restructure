# frozen_string_literal: true

require 'rails_helper'

# Use the activity log player contact phone activity log implementation,
# since it includes the works_with concern

RSpec.describe 'Activity Log implementation', type: :model do
  include ModelSupport
  include PlayerContactSupport

  before :example do
    # SetupHelper.setup_al_player_contact_phones
    # ::ActivityLog.define_models
    create_user
    setup_access :player_contacts
    let_user_create_player_contacts
    create_item(data: rand(10_000_000_000_000_000), rank: 10)
  end

  it 'saves data into an activity log record' do
    data = @player_contact.data

    # Create a second user to ensure that the user attribute is set correctly on saving
    resource_name = :activity_log__player_contact_phone__primary
    user, = create_user
    @player_contact.master.current_user = user
    master = @player_contact.master
    expect(master.current_user).to eq user
    al = @player_contact.activity_log__player_contact_phones.build(select_call_direction: 'from player',
                                                                   select_who: 'user')
    expect(al.master_user).to eq user
    expect(master.activity_log__player_contact_phones).not_to be nil
    expect(al.current_definition).not_to be nil

    expect(al.player_contact).to eq @player_contact

    setup_access resource_name, resource_type: :activity_log_type, access: nil, user: @user

    # Validate that the new activity log item can not be accessed without the appropriate access control
    expect do
      al.save
    end.to raise_error FphsException

    setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create,
                                                       user: al.current_user
    setup_access resource_name, resource_type: :activity_log_type, access: :create, user: al.current_user

    expect(al.current_user.has_access_to?(:create, :table, :activity_log__player_contact_phones)).to be_truthy
    expect(al.current_user.has_access_to?(:create, :activity_log_type, resource_name)).to be_truthy
    # The access has changed, reset the cached results
    al.reset_access_evaluations!

    let_user_create_player_contacts

    expect(al.save).to be true

    expect(al.master_id).to eq @player_contact.master_id
    al.reload
    # We expect data to match, based on an automatic sync of related fields

    expect(al.data).to eq PlayerContact.format_data(data, 'phone')
    expect(al.select_call_direction).to eq 'from player'
    expect(al.select_who).to eq 'user'
    expect(al.user_id).to eq user.id

    setup_access resource_name, resource_type: :activity_log_type, access: nil, user: @user

    expect(@user.has_access_to?(:access, :activity_log_type, resource_name)).to be_falsey

    expect { al.as_json }.to raise_error FphsException
  end
end
