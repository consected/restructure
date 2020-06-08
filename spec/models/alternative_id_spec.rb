# frozen_string_literal: true

require 'rails_helper'

# Use the activity log player contact phone activity log implementation,
# since it includes the works_with concern

RSpec.describe 'Alternative ID implementation', type: :model do
  include ModelSupport
  include PlayerContactSupport

  before :example do
    # seed_database
    create_user

    setup_access :scantrons
    setup_access :player_contacts
    let_user_create :player_contacts

    @master = create_master
    @scantron = Scantron.unscoped.order(scantron_id: :desc).first
    @sid = if @scantron
             @scantron.scantron_id + 1
           else
             1
           end
    @master.scantrons.create! scantron_id: @sid
  end

  it 'creates an item based on an alternative ID, linking it to the master automatically' do
    expect(defined?(ExternalIdentifier::Scantron)).to be_truthy
    expect(Master.alternative_id_fields).to include :scantron_id
    expect(PlayerContact.new).to respond_to 'scantron_id='

    att = valid_attribs.dup

    att[:scantron_id] = @sid

    pc = PlayerContact.new att

    expect(pc.master).to eq @master

    pc.master.current_user = @user

    expect(pc.save).to be true
  end
end
