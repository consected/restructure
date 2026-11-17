# frozen_string_literal: true

# Regression tests for GitHub Issue #1367.
#
# `no_masters: {}` conditional calculations raised
# "No resource found for tracker_history with no_masters specified in calc_actions" because
# TrackerHistory and Tracker were never registered in Resources::Models (unlike sibling static
# UserBase models, which each explicitly call `add_model_to_list`), and separately, TrackerHistory's
# deliberately irregular (singular) `tracker_history` table name did not match its pluralized
# `tracker_histories` resource_name used by the Resources::Models lookup in `setup_no_masters`.
# ItemFlag had the same missing-registration issue and is fixed/covered alongside it.

require 'rails_helper'

RSpec.describe 'no_masters conditional calculations against tracker_history', type: :model do
  include ModelSupport

  before :each do
    create_user
    create_admin
    setup_access :trackers
    setup_access :tracker_histories

    @protocol = Classification::Protocol.create name: 'P1', current_admin: @admin
    @sub_process = @protocol.sub_processes.create name: 'SP1', current_admin: @admin

    @master = Master.new
    @master.current_user = @user
    @master.save!

    @tracker = @master.trackers.create protocol_id: @protocol.id, sub_process_id: @sub_process.id,
                                        event_date: DateTime.now
  end

  it 'registers TrackerHistory and Tracker as valid Resources::Models entries' do
    expect(Resources::Models.find_by(resource_name: :tracker_histories)&.dig(:class_name)).to eq 'TrackerHistory'
    expect(Resources::Models.find_by(resource_name: :trackers)&.dig(:class_name)).to eq 'Tracker'
  end

  it 'registers ItemFlag as a valid Resources::Models entry' do
    expect(Resources::Models.find_by(resource_name: :item_flags)&.dig(:class_name)).to eq 'ItemFlag'
  end

  it 'evaluates a no_masters condition using the tracker_history table name' do
    conf = {
      all: {
        no_masters: {},
        tracker_history: {
          protocol_id: @protocol.id
        }
      }
    }

    res = ConditionalActions.new conf, @tracker
    expect(res.calc_action_if).to be true

    conf[:all][:tracker_history][:protocol_id] = @protocol.id + 1000
    res = ConditionalActions.new conf, @tracker
    expect(res.calc_action_if).to be false
  end

  it 'still raises a clear error for a genuinely unknown resource under no_masters' do
    conf = {
      all: {
        no_masters: {},
        not_a_real_table: {
          id: 1
        }
      }
    }

    expect do
      ConditionalActions.new(conf, @tracker).calc_action_if
    end.to raise_error(FphsException, /No resource found for not_a_real_table/)
  end
end
