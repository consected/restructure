# frozen_string_literal: true

require 'rails_helper'

# Spec for the trackers view and INSTEAD OF INSERT trigger behavior.
# The trackers "table" is now a database view derived from tracker_history using
# DISTINCT ON (master_id, protocol_id) with ORDER BY event_date::date DESC, id DESC.
# Inserts into the view are routed to tracker_history by an INSTEAD OF INSERT trigger.
# Deletes and updates on tracker_history are immediately reflected in the view.
#
# These tests verify:
#   1. INSERT into trackers view creates a tracker_history row
#   2. The view shows the correct "latest" entry per (master_id, protocol_id)
#   3. Deleting tracker_history rows is reflected in the view
#   4. Updating tracker_history rows directly works (no delete-reinsert chain)
#   5. add_tracker_entry_by_name() SQL functions still work
#
# Replaces the old trigger-based tests following issue #941.

RSpec.describe Tracker, type: :model do
  include ModelSupport

  def execute(sql)
    Tracker.connection.execute sql
  end

  before(:each) do
    @user_2, = create_user

    create_user
    create_admin
    @p1 = Classification::Protocol.create name: 'P1-trig', current_admin: @admin
    @p2 = Classification::Protocol.create name: 'P2-trig', current_admin: @admin

    @sp1_1 = @p1.sub_processes.create name: 'SP1-trig', current_admin: @admin
    @sp1_2 = @p1.sub_processes.create name: 'SP12-trig', current_admin: @admin
    @sp1_3 = @p1.sub_processes.create name: 'SP13-trig', current_admin: @admin
    @sp2_1 = @p2.sub_processes.create name: 'SP2-trig', current_admin: @admin
    @sp2_2 = @p2.sub_processes.create name: 'SP22-trig', current_admin: @admin

    @pe2_2_1 = @sp2_2.protocol_events.create name: 'PE221-trig', current_admin: @admin

    @master = Master.new
    @master.current_user = @user
    @master.save!

    @user_id = @user.id
    @user_id_2 = @user_2.id
  end

  describe 'INSERT into trackers view' do
    it 'creates a tracker_history row when inserting into the view' do
      res = execute "
        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id)
        VALUES (#{@master.id}, #{@p1.id}, #{@sp1_1.id}, '#{DateTime.now}', now(), now(), #{@user_id});

        SELECT * FROM trackers WHERE master_id = #{@master.id};
      "

      expect(res.count).to eq 1
      expect(res.first['protocol_id']).to eq @p1.id

      res = execute "SELECT * FROM tracker_history WHERE master_id = #{@master.id} AND protocol_id = #{@p1.id};"
      expect(res.count).to eq 1
    end

    it 'reuses tracker_id when inserting for the same master/protocol pair' do
      execute "
        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id)
        VALUES (#{@master.id}, #{@p1.id}, #{@sp1_1.id}, '#{DateTime.now}', now(), now(), #{@user_id});
      "

      execute "
        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id)
        VALUES (#{@master.id}, #{@p1.id}, #{@sp1_2.id}, '#{DateTime.now}', now(), now(), #{@user_id});
      "

      res = execute "SELECT * FROM trackers WHERE master_id = #{@master.id};"
      expect(res.count).to eq 1
      expect(res.first['protocol_id']).to eq @p1.id

      # Both tracker_history rows should have the same tracker_id
      th_res = execute "SELECT * FROM tracker_history WHERE master_id = #{@master.id} AND protocol_id = #{@p1.id};"
      expect(th_res.count).to eq 2
      tracker_ids = th_res.map { |r| r['tracker_id'] }.uniq
      expect(tracker_ids.length).to eq 1
    end

    it 'generates a new tracker_id for a new master/protocol pair' do
      execute "
        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id)
        VALUES (#{@master.id}, #{@p1.id}, #{@sp1_1.id}, '#{DateTime.now}', now(), now(), #{@user_id});
      "

      execute "
        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id)
        VALUES (#{@master.id}, #{@p2.id}, #{@sp2_1.id}, '#{DateTime.now}', now(), now(), #{@user_id});
      "

      res = execute "SELECT * FROM trackers WHERE master_id = #{@master.id} ORDER BY protocol_id;"
      expect(res.count).to eq 2

      # Different protocols should have different tracker_ids (view id column)
      ids = res.map { |r| r['id'] }
      expect(ids.uniq.length).to eq 2
    end
  end

  describe 'view shows correct latest entry' do
    it 'shows the most recent entry by event_date for a protocol' do
      execute "
        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id)
        VALUES (#{@master.id}, #{@p1.id}, #{@sp1_1.id}, '#{DateTime.now}', now(), now(), #{@user_id});

        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id)
        VALUES (#{@master.id}, #{@p1.id}, #{@sp1_2.id}, '#{DateTime.now}', now(), now(), #{@user_id});
      "

      res = execute "SELECT * FROM trackers WHERE master_id = #{@master.id};"
      expect(res.count).to eq 1
      # Both entries have the same event_date (same day), so the one with higher id wins
      expect(res.first['sub_process_id']).to eq @sp1_2.id
    end

    it 'does not change the view result when an older event_date entry is inserted' do
      execute "
        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id)
        VALUES (#{@master.id}, #{@p1.id}, #{@sp1_1.id}, '#{DateTime.now}', now(), now(), #{@user_id});

        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id)
        VALUES (#{@master.id}, #{@p1.id}, #{@sp1_2.id}, '#{DateTime.now}', now(), now(), #{@user_id});

        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id)
        VALUES (#{@master.id}, #{@p1.id}, #{@sp1_3.id}, '#{DateTime.now - 1.day}', now(), now(), #{@user_id});
      "

      res = execute "SELECT * FROM trackers WHERE master_id = #{@master.id};"
      t = res.first
      expect(res.count).to eq 1
      expect(t['protocol_id']).to eq @p1.id
      # sp1_2 has the same date as sp1_1 but higher id, so sp1_2 should be shown
      expect(t['sub_process_id']).to eq @sp1_2.id

      res = execute "SELECT * FROM tracker_history WHERE master_id = #{@master.id} AND protocol_id = #{@p1.id};"
      expect(res.count).to eq 3
    end
  end

  describe 'deleting tracker_history rows' do
    it 'removes the view row when the only tracker_history entry is deleted' do
      execute "
        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id)
        VALUES (#{@master.id}, #{@p2.id}, #{@sp2_1.id}, '#{DateTime.now}', now(), now(), #{@user_id});
      "

      execute "DELETE FROM tracker_history WHERE master_id = #{@master.id} AND protocol_id = #{@p2.id};"

      res = execute "SELECT * FROM trackers WHERE master_id = #{@master.id} AND protocol_id = #{@p2.id};"
      expect(res.count).to eq 0

      res = execute "SELECT * FROM tracker_history WHERE master_id = #{@master.id} AND protocol_id = #{@p2.id};"
      expect(res.count).to eq 0
    end

    it 'does not change the view when an older tracker_history entry is deleted' do
      execute "
        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id)
        VALUES (#{@master.id}, #{@p2.id}, #{@sp2_1.id}, '#{DateTime.now}', now(), now(), #{@user_id});

        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id)
        VALUES (#{@master.id}, #{@p2.id}, #{@sp2_2.id}, '#{DateTime.now - 1.day}', now(), now(), #{@user_id});
      "

      execute "
        DELETE FROM tracker_history
        WHERE master_id = #{@master.id} AND protocol_id = #{@p2.id} AND sub_process_id = #{@sp2_2.id};
      "

      res = execute "SELECT * FROM trackers WHERE master_id = #{@master.id} AND protocol_id = #{@p2.id};"
      expect(res.count).to eq 1
      t = res.first
      expect(t['sub_process_id']).to eq @sp2_1.id

      res = execute "SELECT * FROM tracker_history WHERE master_id = #{@master.id} AND protocol_id = #{@p2.id};"
      expect(res.count).to eq(1), "Incorrect count #{res.count}. #{res.select(&:inspect)}"
      t = res.first
      expect(t['sub_process_id']).to eq @sp2_1.id
    end

    it 'updates the view when the most recent tracker_history entry is deleted' do
      execute "
        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id)
        VALUES (#{@master.id}, #{@p2.id}, #{@sp2_1.id}, '#{DateTime.now}', now(), now(), #{@user_id});

        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id)
        VALUES (#{@master.id}, #{@p2.id}, #{@sp2_2.id}, '#{DateTime.now - 1.day}', now(), now(), #{@user_id});
      "

      execute "
        DELETE FROM tracker_history
        WHERE master_id = #{@master.id} AND protocol_id = #{@p2.id} AND sub_process_id = #{@sp2_1.id};
      "

      res = execute "SELECT * FROM trackers WHERE master_id = #{@master.id} AND protocol_id = #{@p2.id};"
      expect(res.count).to eq 1
      t = res.first
      expect(t['sub_process_id']).to eq @sp2_2.id

      res = execute "SELECT * FROM tracker_history WHERE master_id = #{@master.id} AND protocol_id = #{@p2.id};"
      expect(res.count).to eq 1
      t = res.first
      expect(t['sub_process_id']).to eq @sp2_2.id
    end
  end

  describe 'updating tracker_history directly' do
    it 'updates an older tracker_history record in-place without affecting the view' do
      dt = DateTime.now - 2.days
      dt1 = DateTime.now - 1.day

      execute "
        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id)
        VALUES (#{@master.id}, #{@p2.id}, #{@sp2_1.id}, '#{DateTime.now}', now(), now(), #{@user_id});

        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id, notes)
        VALUES (#{@master.id}, #{@p2.id}, #{@sp2_2.id}, '#{dt1}', now(), now(), #{@user_id}, 'done1 #{dt1.to_i}');

        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id, notes)
        VALUES (#{@master.id}, #{@p2.id}, #{@sp2_2.id}, '#{dt}', now(), now(), #{@user_id}, 'done #{dt.to_i}');
      "

      # Update a non-latest entry directly
      execute "UPDATE tracker_history SET protocol_event_id = #{@pe2_2_1.id} WHERE notes = 'done #{dt.to_i}';"

      res = execute "SELECT * FROM trackers WHERE master_id = #{@master.id} AND protocol_id = #{@p2.id};"
      expect(res.count).to eq 1
      t = res.first
      expect(t['sub_process_id']).to eq @sp2_1.id

      res = execute "SELECT * FROM tracker_history WHERE master_id = #{@master.id} AND protocol_id = #{@p2.id} ORDER BY id DESC;"
      expect(res.count).to eq 3
      t = res.first
      expect(t['sub_process_id']).to eq @sp2_2.id
      expect(t['protocol_event_id']).to eq @pe2_2_1.id
      expect(t['notes']).to eq "done #{dt.to_i}"
    end

    it 'updates the most recent tracker_history record in-place, reflecting in the view' do
      dt = DateTime.now - 15.days
      dt1 = DateTime.now - 10.days
      dt0 = DateTime.now - 8.days

      execute "
        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id, notes)
        VALUES (#{@master.id}, #{@p2.id}, #{@sp2_1.id}, '#{dt0}', now(), now(), #{@user_id}, 'orig #{dt0.to_i}');

        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id, notes)
        VALUES (#{@master.id}, #{@p2.id}, #{@sp2_2.id}, '#{dt1}', now(), now(), #{@user_id}, 'done1 #{dt1.to_i}');

        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id, notes)
        VALUES (#{@master.id}, #{@p2.id}, #{@sp2_2.id}, '#{dt}', now(), now(), #{@user_id}, 'done #{dt.to_i}');
      "

      execute "UPDATE tracker_history SET user_id = #{@user_id_2} WHERE notes = 'orig #{dt0.to_i}';"

      res = execute "SELECT * FROM trackers WHERE master_id = #{@master.id} AND protocol_id = #{@p2.id};"
      expect(res.count).to eq 1
      t = res.first
      expect(t['sub_process_id']).to eq @sp2_1.id
      expect(t['user_id']).to eq @user_id_2

      # Verify the updated tracker_history row by finding it via notes
      res = execute "SELECT * FROM tracker_history WHERE master_id = #{@master.id} AND protocol_id = #{@p2.id} ORDER BY event_date::date DESC NULLS LAST, id DESC;"
      expect(res.count).to eq 3
      t = res.first
      expect(t['sub_process_id']).to eq @sp2_1.id
      expect(t['notes']).to eq "orig #{dt0.to_i}"
      expect(t['user_id']).to eq @user_id_2
    end

    it 'updates protocol_id on a tracker_history record, moving it to a new protocol group' do
      dt = DateTime.now - 15.days
      dt1 = DateTime.now - 10.days
      dt0 = DateTime.now - 8.days

      execute "
        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id, notes)
        VALUES (#{@master.id}, #{@p2.id}, #{@sp2_1.id}, '#{dt0}', now(), now(), #{@user_id}, 'orig #{dt0.to_i}');

        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id, notes)
        VALUES (#{@master.id}, #{@p2.id}, #{@sp2_2.id}, '#{dt1}', now(), now(), #{@user_id}, 'done1 #{dt1.to_i}');

        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id, notes)
        VALUES (#{@master.id}, #{@p2.id}, #{@sp2_2.id}, '#{dt}', now(), now(), #{@user_id}, 'done #{dt.to_i}');
      "

      execute "UPDATE tracker_history SET protocol_id = #{@p1.id}, sub_process_id = #{@sp1_1.id} WHERE notes = 'orig #{dt0.to_i}';"

      res = execute "SELECT * FROM trackers WHERE master_id = #{@master.id} ORDER BY event_date DESC;"
      expect(res.count).to eq 2

      p1_row = res.find { |r| r['protocol_id'] == @p1.id }
      expect(p1_row['sub_process_id']).to eq @sp1_1.id

      p2_row = res.find { |r| r['protocol_id'] == @p2.id }
      expect(p2_row['sub_process_id']).to eq @sp2_2.id

      res = execute "SELECT * FROM tracker_history WHERE master_id = #{@master.id} AND protocol_id = #{@p2.id} ORDER BY event_date DESC, id DESC;"
      expect(res.count).to eq 2
      t = res[0]
      expect(t['sub_process_id']).to eq @sp2_2.id
      expect(t['notes']).to eq "done1 #{dt1.to_i}"

      res = execute "SELECT * FROM tracker_history WHERE master_id = #{@master.id} AND protocol_id = #{@p1.id};"
      expect(res.count).to eq 1
      t = res[0]
      expect(t['sub_process_id']).to eq @sp1_1.id
      expect(t['notes']).to eq "orig #{dt0.to_i}"
    end

    it 'updates event_date on a tracker_history record, reflecting in the view' do
      dt = DateTime.now - 15.days
      dt1 = DateTime.now - 10.days
      dt0 = DateTime.now - 8.days

      execute "
        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id, notes)
        VALUES (#{@master.id}, #{@p2.id}, #{@sp2_1.id}, '#{dt0}', now(), now(), #{@user_id}, 'orig #{dt0.to_i}');

        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id, notes)
        VALUES (#{@master.id}, #{@p2.id}, #{@sp2_2.id}, '#{dt1}', now(), now(), #{@user_id}, 'done1 #{dt1.to_i}');

        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id, notes)
        VALUES (#{@master.id}, #{@p2.id}, #{@sp2_2.id}, '#{dt}', now(), now(), #{@user_id}, 'done #{dt.to_i}');
      "

      dtnew = DateTime.now - 5.days
      execute "UPDATE tracker_history SET event_date = '#{dtnew}' WHERE notes = 'orig #{dt0.to_i}';"

      res = execute "SELECT * FROM trackers WHERE master_id = #{@master.id};"
      expect(res.count).to eq 1
      t = res[0]
      expect(t['sub_process_id']).to eq @sp2_1.id
      expect(t['protocol_id']).to eq @p2.id

      res = execute "SELECT * FROM tracker_history WHERE master_id = #{@master.id} AND protocol_id = #{@p2.id} ORDER BY event_date DESC, id DESC;"
      expect(res.count).to eq 3
      t = res[0]
      expect(t['sub_process_id']).to eq @sp2_1.id
      expect(t['notes']).to eq "orig #{dt0.to_i}"
    end
  end

  describe 'add_tracker_entry_by_name SQL function' do
    it 'creates a tracker entry via the SQL function' do
      protocol = Classification::Protocol.create! name: 'Test-abn-proto', current_admin: @admin
      sp = protocol.sub_processes.create! name: 'Test-abn-sp', current_admin: @admin
      pe = sp.protocol_events.create! name: 'Test-abn-pe', current_admin: @admin

      execute "SELECT add_tracker_entry_by_name(#{@master.id}, 'Test-abn-proto', 'Test-abn-sp', 'Test-abn-pe', 'test notes', #{@user_id}, NULL, NULL);"

      res = execute "SELECT * FROM trackers WHERE master_id = #{@master.id} AND protocol_id = #{protocol.id};"
      expect(res.count).to eq 1
      t = res.first
      expect(t['sub_process_id']).to eq sp.id
      expect(t['protocol_event_id']).to eq pe.id

      th_res = execute "SELECT * FROM tracker_history WHERE master_id = #{@master.id} AND protocol_id = #{protocol.id};"
      expect(th_res.count).to eq 1
      expect(th_res.first['notes']).to eq 'test notes'
    end
  end
end
