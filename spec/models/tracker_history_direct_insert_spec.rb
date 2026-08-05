# frozen_string_literal: true

require 'rails_helper'
require_relative '../../db/migrate/20260730120000_assign_tracker_id_deterministically_on_tracker_history'

# Spec for tracker_history.tracker_id population via
# tracker_history_assign_tracker_id_trigger, a BEFORE INSERT OR UPDATE trigger
# that unconditionally recomputes tracker_id from master_id/protocol_id.
#
# tracker_history is "routinely inserted to outside the app" (see TrackerHistory
# model comment) by external systems and scripted jobs. tracker_id is a pure,
# deterministic function of (master_id, protocol_id):
#
#   tracker_id = master_id::bigint * 1_000_000 + protocol_id
#
# computed by a trigger on every INSERT and UPDATE (not a Postgres generated
# column - that would require dropping/re-adding the column, which cascades to
# drop any view that reads it, including admin-configured dynamic-model views
# this migration can't know about). Key properties:
#
#   - tracker_id is always non-NULL for any row with non-NULL master_id and
#     protocol_id (enforced by both the trigger and a NOT NULL backstop).
#   - All rows in the same (master_id, protocol_id) group share the same
#     tracker_id by construction (same formula, same inputs).
#   - Different groups always have different tracker_ids (the formula is
#     injective given protocol_id < 1_000_000).
#   - Supplying an explicit tracker_id in an INSERT or UPDATE is silently
#     overwritten with the computed value - there is nothing to reject, since
#     the trigger recomputes tracker_id unconditionally on every write.
#   - Updating master_id or protocol_id automatically recomputes tracker_id.
#   - Legacy rows that previously had NULL tracker_id (or an old sequence-
#     derived value) are recomputed by a one-time UPDATE run by the migration.
#
# See: https://github.com/consected/restructure/issues/1309
RSpec.describe TrackerHistory, type: :model do
  include ModelSupport

  def execute(sql)
    Tracker.connection.execute sql
  end

  before(:each) do
    create_user
    create_admin

    @p1 = Classification::Protocol.create name: 'P1-direct', current_admin: @admin
    @p2 = Classification::Protocol.create name: 'P2-direct', current_admin: @admin
    @sp1 = @p1.sub_processes.create name: 'SP1-direct', current_admin: @admin
    @sp2 = @p2.sub_processes.create name: 'SP2-direct', current_admin: @admin

    @master1 = Master.new
    @master1.current_user = @user
    @master1.save!

    @master2 = Master.new
    @master2.current_user = @user
    @master2.save!

    @user_id = @user.id
  end

  # Directly insert a tracker_history row WITHOUT specifying tracker_id,
  # simulating an external system or scripted job writing to the table without
  # going through the trackers view. tracker_id is not included in the column
  # list here since the trigger overwrites it regardless (see the 'tracker_id
  # is always overwritten...' describe block below for tests that explicitly
  # supply a value anyway).
  def direct_insert(sub_process:, notes:, master: nil, protocol: nil, event_date: DateTime.now)
    master_id_sql = master ? master.id : 'NULL'
    protocol_id_sql = protocol ? protocol.id : 'NULL'

    execute <<~SQL
      INSERT INTO tracker_history
      (master_id, protocol_id, sub_process_id, event_date, created_at, updated_at, user_id, notes)
      VALUES
      (#{master_id_sql}, #{protocol_id_sql}, #{sub_process.id}, '#{event_date}', now(), now(), #{@user_id}, '#{notes}');
    SQL
  end

  describe 'direct INSERT into tracker_history' do
    it 'assigns a non-null tracker_id automatically' do
      direct_insert master: @master1, protocol: @p1, sub_process: @sp1, notes: 'external entry'

      res = execute "SELECT * FROM tracker_history WHERE master_id = #{@master1.id} AND protocol_id = #{@p1.id};"
      expect(res.count).to eq 1
      expect(res.first['tracker_id']).not_to be_nil
    end

    it 'shows a non-null id in the trackers view' do
      direct_insert master: @master1, protocol: @p1, sub_process: @sp1, notes: 'external entry'

      t = Tracker.where(master_id: @master1.id, protocol_id: @p1.id).first
      expect(t).not_to be_nil
      expect(t.id).not_to be_nil
    end

    it 'reuses the same tracker_id for a second direct insert into the same master/protocol group' do
      direct_insert master: @master1, protocol: @p1, sub_process: @sp1, notes: 'entry 1'
      direct_insert master: @master1, protocol: @p1, sub_process: @sp1, notes: 'entry 2'

      res = execute "SELECT * FROM tracker_history WHERE master_id = #{@master1.id} AND protocol_id = #{@p1.id};"
      expect(res.count).to eq 2
      tracker_ids = res.map { |r| r['tracker_id'] }.uniq
      expect(tracker_ids.length).to eq 1
      expect(tracker_ids.first).not_to be_nil
    end

    it 'assigns different tracker_ids to different master/protocol groups inserted directly' do
      direct_insert master: @master1, protocol: @p1, sub_process: @sp1, notes: 'group 1'
      direct_insert master: @master2, protocol: @p2, sub_process: @sp2, notes: 'group 2'

      t1 = Tracker.where(master_id: @master1.id, protocol_id: @p1.id).first
      t2 = Tracker.where(master_id: @master2.id, protocol_id: @p2.id).first

      expect(t1.id).not_to be_nil
      expect(t2.id).not_to be_nil
      expect(t1.id).not_to eq t2.id
    end

    it 'does not cross-contaminate tracker_histories between different directly-inserted groups' do
      direct_insert master: @master1, protocol: @p1, sub_process: @sp1, notes: 'group 1 entry'
      direct_insert master: @master2, protocol: @p2, sub_process: @sp2, notes: 'group 2 entry a'
      direct_insert master: @master2, protocol: @p2, sub_process: @sp2, notes: 'group 2 entry b'

      t1 = Tracker.where(master_id: @master1.id, protocol_id: @p1.id).first
      t2 = Tracker.where(master_id: @master2.id, protocol_id: @p2.id).first

      expect(t1.tracker_histories.count).to eq 1
      expect(t2.tracker_histories.count).to eq 2
      expect(t1.tracker_histories.pluck(:notes)).to eq ['group 1 entry']
    end

    it 'computes tracker_id deterministically as master_id * 1_000_000 + protocol_id' do
      direct_insert master: @master1, protocol: @p1, sub_process: @sp1, notes: 'deterministic check'

      res = execute "SELECT tracker_id FROM tracker_history WHERE master_id = #{@master1.id} AND protocol_id = #{@p1.id};"
      expected_tracker_id = (@master1.id * 1_000_000) + @p1.id
      expect(res.first['tracker_id'].to_i).to eq expected_tracker_id
    end

    it 'reuses a tracker_id assigned by a direct insert when a later insert goes through the trackers view' do
      # The group is first established purely by direct inserts (bypassing the view).
      direct_insert master: @master1, protocol: @p1, sub_process: @sp1, notes: 'first direct entry'
      direct_tracker_id = execute(
        "SELECT tracker_id FROM tracker_history WHERE master_id = #{@master1.id} AND protocol_id = #{@p1.id};"
      ).first['tracker_id']
      expect(direct_tracker_id).not_to be_nil

      # A subsequent insert for the same master/protocol goes through the normal
      # trackers view path (e.g. a user adds a tracker record via the app).
      execute <<~SQL
        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id, notes)
        VALUES (#{@master1.id}, #{@p1.id}, #{@sp1.id}, now(), now(), now(), #{@user_id}, 'later view entry');
      SQL

      res = execute "SELECT * FROM tracker_history WHERE master_id = #{@master1.id} AND protocol_id = #{@p1.id};"
      expect(res.count).to eq 2
      tracker_ids = res.map { |r| r['tracker_id'] }.uniq
      expect(tracker_ids).to eq [direct_tracker_id]
    end

    it 'accumulates three or more direct inserts into the same master/protocol group under one tracker_id' do
      direct_insert master: @master1, protocol: @p1, sub_process: @sp1, notes: 'entry 1'
      direct_insert master: @master1, protocol: @p1, sub_process: @sp1, notes: 'entry 2'
      direct_insert master: @master1, protocol: @p1, sub_process: @sp1, notes: 'entry 3'

      res = execute "SELECT * FROM tracker_history WHERE master_id = #{@master1.id} AND protocol_id = #{@p1.id};"
      expect(res.count).to eq 3
      tracker_ids = res.map { |r| r['tracker_id'] }.uniq
      expect(tracker_ids.length).to eq 1

      t = Tracker.where(master_id: @master1.id, protocol_id: @p1.id).first
      expect(t.tracker_histories.count).to eq 3
    end
  end

  describe 'tracker_id is always overwritten with the deterministic computed value' do
    # tracker_history_assign_tracker_id_trigger fires on every INSERT and
    # UPDATE and unconditionally recomputes tracker_id from master_id and
    # protocol_id, regardless of what value the statement attempted to set -
    # through any path: the trackers view, a direct SQL statement, an
    # external system. There is nothing to reject: any explicitly-supplied
    # value is silently replaced with the only value that could ever be
    # correct for that row's master_id/protocol_id.

    it 'overwrites an explicitly-supplied tracker_id value on INSERT with the computed value' do
      execute <<~SQL
        INSERT INTO tracker_history
        (master_id, protocol_id, sub_process_id, event_date, created_at, updated_at, user_id, notes, tracker_id)
        VALUES
        (#{@master1.id}, #{@p1.id}, #{@sp1.id}, now(), now(), now(), #{@user_id}, 'explicit id entry', 999999999);
      SQL

      expected_tracker_id = (@master1.id * 1_000_000) + @p1.id
      res = execute "SELECT tracker_id FROM tracker_history WHERE master_id = #{@master1.id} AND protocol_id = #{@p1.id};"
      expect(res.first['tracker_id'].to_i).to eq expected_tracker_id
    end

    it 'overwrites tracker_id on INSERT even when the supplied value matches the correct computed value' do
      # Confirms the trigger always recomputes rather than trusting a
      # caller-supplied value, even a coincidentally-correct one.
      correct_value = (@master1.id * 1_000_000) + @p1.id
      execute <<~SQL
        INSERT INTO tracker_history
        (master_id, protocol_id, sub_process_id, event_date, created_at, updated_at, user_id, notes, tracker_id)
        VALUES
        (#{@master1.id}, #{@p1.id}, #{@sp1.id}, now(), now(), now(), #{@user_id}, 'correct guess entry', #{correct_value});
      SQL

      res = execute "SELECT tracker_id FROM tracker_history WHERE master_id = #{@master1.id} AND protocol_id = #{@p1.id};"
      expect(res.first['tracker_id'].to_i).to eq correct_value
    end

    it 'overwrites a raw SQL UPDATE that attempts to SET tracker_id explicitly' do
      direct_insert master: @master1, protocol: @p1, sub_process: @sp1, notes: 'normal entry'
      expected_tracker_id = (@master1.id * 1_000_000) + @p1.id

      execute <<~SQL
        UPDATE tracker_history SET tracker_id = 12345
        WHERE master_id = #{@master1.id} AND protocol_id = #{@p1.id};
      SQL

      res = execute "SELECT tracker_id FROM tracker_history WHERE master_id = #{@master1.id} AND protocol_id = #{@p1.id};"
      expect(res.first['tracker_id'].to_i).to eq expected_tracker_id
    end

    it 'overwrites a raw SQL UPDATE that attempts to SET tracker_id to NULL' do
      direct_insert master: @master1, protocol: @p1, sub_process: @sp1, notes: 'normal entry'
      expected_tracker_id = (@master1.id * 1_000_000) + @p1.id

      execute <<~SQL
        UPDATE tracker_history SET tracker_id = NULL
        WHERE master_id = #{@master1.id} AND protocol_id = #{@p1.id};
      SQL

      res = execute "SELECT tracker_id FROM tracker_history WHERE master_id = #{@master1.id} AND protocol_id = #{@p1.id};"
      expect(res.first['tracker_id']).not_to be_nil
      expect(res.first['tracker_id'].to_i).to eq expected_tracker_id
    end
  end

  describe 'bulk/multi-row statements inserting several rows for the same brand-new group at once' do
    # Under the trigger-based design, all rows sharing the same
    # (master_id, protocol_id) get the same tracker_id by construction -
    # there is no race condition possible, unlike a sequence/lookup approach.
    it 'assigns a single shared tracker_id when three rows for a new group arrive in one multi-row INSERT' do
      execute <<~SQL
        INSERT INTO tracker_history
        (master_id, protocol_id, sub_process_id, event_date, created_at, updated_at, user_id, notes)
        VALUES
        (#{@master1.id}, #{@p1.id}, #{@sp1.id}, now(), now(), now(), #{@user_id}, 'multi-row entry 1'),
        (#{@master1.id}, #{@p1.id}, #{@sp1.id}, now(), now(), now(), #{@user_id}, 'multi-row entry 2'),
        (#{@master1.id}, #{@p1.id}, #{@sp1.id}, now(), now(), now(), #{@user_id}, 'multi-row entry 3');
      SQL

      res = execute "SELECT * FROM tracker_history WHERE master_id = #{@master1.id} AND protocol_id = #{@p1.id};"
      expect(res.count).to eq 3
      tracker_ids = res.map { |r| r['tracker_id'] }
      expect(tracker_ids).to all(be_present)
      expect(tracker_ids.uniq.length).to eq 1
    end

    it 'assigns a single shared tracker_id when rows for a new group arrive via COPY FROM STDIN' do
      raw_connection = Tracker.connection.raw_connection
      now = Time.now.strftime('%Y-%m-%d %H:%M:%S')

      raw_connection.copy_data(
        'COPY tracker_history (master_id, protocol_id, sub_process_id, event_date, created_at, updated_at, ' \
        'user_id, notes) FROM STDIN'
      ) do
        raw_connection.put_copy_data "#{@master2.id}\t#{@p2.id}\t#{@sp2.id}\t#{now}\t#{now}\t#{now}\t#{@user_id}\t" \
                                     "copy entry 1\n"
        raw_connection.put_copy_data "#{@master2.id}\t#{@p2.id}\t#{@sp2.id}\t#{now}\t#{now}\t#{now}\t#{@user_id}\t" \
                                     "copy entry 2\n"
      end

      res = execute "SELECT * FROM tracker_history WHERE master_id = #{@master2.id} AND protocol_id = #{@p2.id};"
      expect(res.count).to eq 2
      tracker_ids = res.map { |r| r['tracker_id'] }
      expect(tracker_ids).to all(be_present)
      expect(tracker_ids.uniq.length).to eq 1
    end
  end

  describe 'direct INSERT with a NULL master_id or protocol_id' do
    # A tracker_history row is meaningless without a master_id and protocol_id
    # (it can never be grouped or displayed), so the database enforces this
    # with NOT NULL constraints rather than the app tolerating/working around
    # such rows.
    it 'rejects a direct insert with a NULL master_id' do
      expect do
        direct_insert master: nil, protocol: @p1, sub_process: @sp1, notes: 'no master entry'
      end.to raise_error(ActiveRecord::NotNullViolation)
    end

    it 'rejects a direct insert with a NULL protocol_id' do
      expect do
        direct_insert master: @master1, protocol: nil, sub_process: @sp1, notes: 'no protocol entry'
      end.to raise_error(ActiveRecord::NotNullViolation)
    end
  end

  describe 'directly UPDATE-ing master_id/protocol_id on tracker_history, moving it to a different group' do
    # The tracker_id trigger fires on UPDATE too, so it auto-recomputes when
    # master_id/protocol_id change. Updating master_id or protocol_id
    # automatically changes tracker_id to match the destination group's
    # value, with no lookup or lock required.
    it 'assigns a fresh tracker_id when moving a row into a brand-new group, leaving the source group untouched' do
      execute <<~SQL
        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id, notes)
        VALUES (#{@master1.id}, #{@p1.id}, #{@sp1.id}, now(), now(), now(), #{@user_id}, 'source entry 1');

        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id, notes)
        VALUES (#{@master1.id}, #{@p1.id}, #{@sp1.id}, now(), now(), now(), #{@user_id}, 'source entry 2');
      SQL

      source_tracker_id = execute(
        "SELECT tracker_id FROM tracker_history WHERE master_id = #{@master1.id} AND protocol_id = #{@p1.id} " \
        "AND notes = 'source entry 1';"
      ).first['tracker_id']

      # Move one row directly to p2 - a brand-new group for this master - simulating
      # an external system correcting a mis-filed entry.
      execute(
        "UPDATE tracker_history SET protocol_id = #{@p2.id}, sub_process_id = #{@sp2.id} " \
        "WHERE master_id = #{@master1.id} AND notes = 'source entry 1';"
      )

      moved_row = execute(
        "SELECT * FROM tracker_history WHERE master_id = #{@master1.id} AND protocol_id = #{@p2.id};"
      ).first
      expect(moved_row['tracker_id']).not_to be_nil
      expect(moved_row['tracker_id']).not_to eq source_tracker_id

      remaining_source = execute(
        "SELECT * FROM tracker_history WHERE master_id = #{@master1.id} AND protocol_id = #{@p1.id};"
      )
      expect(remaining_source.count).to eq 1
      expect(remaining_source.first['tracker_id']).to eq source_tracker_id

      # The trackers view now shows two distinct groups with two distinct ids,
      # instead of both groups incorrectly sharing the source group's id.
      p1_tracker = Tracker.where(master_id: @master1.id, protocol_id: @p1.id).first
      p2_tracker = Tracker.where(master_id: @master1.id, protocol_id: @p2.id).first
      expect(p1_tracker.id).to eq source_tracker_id
      expect(p2_tracker.id).to eq moved_row['tracker_id']
      expect(p1_tracker.id).not_to eq p2_tracker.id
    end

    it 'reuses the destination group\'s existing tracker_id when moving a row into an already-established group' do
      execute <<~SQL
        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id, notes)
        VALUES (#{@master1.id}, #{@p1.id}, #{@sp1.id}, now(), now(), now(), #{@user_id}, 'to be moved');

        INSERT INTO trackers
        (master_id, protocol_id, sub_process_id, event_date, updated_at, created_at, user_id, notes)
        VALUES (#{@master1.id}, #{@p2.id}, #{@sp2.id}, now(), now(), now(), #{@user_id}, 'destination entry');
      SQL

      destination_tracker_id = execute(
        "SELECT tracker_id FROM tracker_history WHERE master_id = #{@master1.id} AND protocol_id = #{@p2.id};"
      ).first['tracker_id']

      execute(
        "UPDATE tracker_history SET protocol_id = #{@p2.id}, sub_process_id = #{@sp2.id} " \
        "WHERE master_id = #{@master1.id} AND notes = 'to be moved';"
      )

      res = execute(
        "SELECT * FROM tracker_history WHERE master_id = #{@master1.id} AND protocol_id = #{@p2.id};"
      )
      expect(res.count).to eq 2
      expect(res.map { |r| r['tracker_id'] }.uniq).to eq [destination_tracker_id]
    end
  end

  describe 'AssignTrackerIdDeterministicallyOnTrackerHistory migration guards' do
    # Only check_for_null_group_columns! is retained here - it guards a
    # prerequisite (no NULL master_id/protocol_id rows) that is still required
    # before tracker_id's NOT NULL constraint can be added. The other guards
    # (check_for_tracker_id_group_conflicts!, resync_tracker_id_seq!) are
    # removed: under the deterministic-trigger design, group conflicts and
    # sequence drift are impossible by construction (tracker_id is a pure
    # function of master_id and protocol_id, not a sequence value).
    let(:migration) { AssignTrackerIdDeterministicallyOnTrackerHistory.new }

    describe 'check_for_null_group_columns!' do
      it 'raises when a tracker_history row has a NULL master_id or protocol_id' do
        # A NULL master_id makes the trigger's formula (master_id * multiplier
        # + protocol_id) evaluate to NULL too, so tracker_id's own NOT NULL
        # constraint must be relaxed alongside master_id's to allow inserting
        # this simulated legacy bad row at all.
        execute 'ALTER TABLE tracker_history ALTER COLUMN master_id DROP NOT NULL;'
        execute 'ALTER TABLE tracker_history ALTER COLUMN tracker_id DROP NOT NULL;'
        direct_insert master: nil, protocol: @p1, sub_process: @sp1, notes: 'bad row'

        expect do
          migration.send(:check_for_null_group_columns!)
        end.to raise_error(/NULL master_id or protocol_id/)

        execute 'DELETE FROM tracker_history WHERE master_id IS NULL;'
        execute 'ALTER TABLE tracker_history ALTER COLUMN master_id SET NOT NULL;'
        execute 'ALTER TABLE tracker_history ALTER COLUMN tracker_id SET NOT NULL;'
      end

      it 'does not raise when no row has a NULL master_id or protocol_id' do
        direct_insert master: @master1, protocol: @p1, sub_process: @sp1, notes: 'fine row'

        expect { migration.send(:check_for_null_group_columns!) }.not_to raise_error
      end
    end
  end
end
