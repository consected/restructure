require 'rails_helper'

# Use the activity log player contact phone activity log implementation,
# since it includes the works_with concern

RSpec.describe 'Alternative ID implementation', type: :model do

  include ModelSupport
  include PlayerContactSupport

  before :all do
    seed_database
    create_user
    @master = create_master
    @scantron = Scantron.unscoped.order(scantron_id: :desc).first
    if @scantron
      @sid = @scantron.scantron_id + 1
    else
      @sid = 1
    end
    @master.scantrons.create! scantron_id: @sid
  end

  it "creates an item based on an alternative ID, linking it to the master automatically" do

    att = valid_attribs.dup

    att[:scantron_id] = @sid


    pc = PlayerContact.new att

    expect(pc.master).to eq @master

    pc.master.current_user = @user

    expect(pc.save).to be true


  end


end
