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

    @scantron_uac = setup_access :scantrons
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

    expect(defined?(Scantron)).to be_truthy
    expect(Master.alternative_id_fields).to include :scantron_id
    expect(PlayerContact.new).to respond_to 'scantron_id='
  end

  it 'creates an item based on an alternative ID, linking it to the master automatically' do
    att = valid_attribs.dup
    # Specify an alternative ID instead of a master_id
    att[:scantron_id] = @sid
    expect(att.keys).not_to include :master
    expect(att.keys).not_to include 'master'

    pc = PlayerContact.new att

    expect(pc.master).to eq @master
    pc.master.current_user = @user

    expect(pc.save).to be true
  end

  it 'enforces user access to alternative ids' do
    att = valid_attribs.dup
    # Specify an alternative ID instead of a master_id
    att[:scantron_id] = @sid
    expect(att.keys).not_to include :master
    expect(att.keys).not_to include 'master'

    pc = PlayerContact.new att

    expect(pc.master).to eq @master
    pc.master.current_user = @user

    expect(pc.save).to be true

    res = Master.find_with_alternative_id(:scantron_id, @sid, @user)
    expect(res).to be_a Master
    expect(res.id).to eq pc.master_id

    @scantron_uac.update! access: nil, user: @user

    Master.reset_external_id_matching_fields!
    expect(@user.has_access_to?(:access, :table, 'scantrons')).to be_falsey
    expect(Master.alternative_id_fields(access_by: @user)).not_to include :scantron_id

    expect { Master.find_with_alternative_id(:scantron_id, @sid, @user) }.to raise_error FphsException
  end
end
