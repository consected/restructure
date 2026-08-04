# frozen_string_literal: true

# Ensure tracker_history.tracker_id is always populated, even when rows are
# inserted directly into tracker_history rather than through the trackers view.
#
# tracker_history is "routinely inserted to outside the app" (external systems,
# scripted jobs) writing directly to the table, bypassing the trackers view's
# INSTEAD OF INSERT trigger (trackers_instead_of_insert, see
# 20260304120000_replace_trackers_table_with_view.rb) that previously assigned
# tracker_id. This left tracker_id NULL for such rows, which in turn caused:
#   - the trackers view to report a NULL id for the affected master/protocol
#     group (id is derived as `tracker_id AS id`)
#   - the tracker summary panel template to skip the row (it checks {{#if id}})
#   - Tracker#tracker_histories (has_many keyed on tracker_id) to match every
#     other NULL tracker_id row in the table via `WHERE tracker_id IS NULL`,
#     cross-contaminating unrelated master/protocol groups
#
# tracker_id becomes a pure, deterministic function of the row's own
# master_id and protocol_id:
#
#   tracker_id = master_id::bigint * MULTIPLIER + protocol_id
#
# maintained by a trigger that unconditionally overwrites tracker_id on every
# INSERT or UPDATE, regardless of what value was supplied - through any path
# (the trackers view, a direct SQL statement, an external system). Because the
# formula only reads columns already present on NEW, there is no lookup
# involved and therefore no possibility of a race between concurrent inserts
# for the same group - no advisory lock is needed, unlike a sequence/lookup-
# based assignment. A CHECK constraint on protocols.id (added below) guards
# the assumption that protocol_id stays below MULTIPLIER.
#
# Two earlier versions of this migration tried to make tracker_id a Postgres
# `GENERATED ALWAYS AS (...) STORED` column, and then a plain bigint column
# widened via `ALTER COLUMN ... TYPE bigint`. Both require changing
# tracker_id's type or dropping/re-adding it - and Postgres refuses either
# operation outright ("cannot alter type of a column used by a view or rule")
# on any column a view depends on. That includes not just the `trackers`
# view, but arbitrary admin-configured dynamic-model views that can exist on
# any deployment of this app, none of which this migration can know about or
# safely recreate.
#
# Rather than requiring every existing database to have its dependent views
# dropped, this migration detects whether it is safe to widen tracker_id to
# bigint (use_wide_tracker_id?: true in development/test; in production, only
# when there are no master records older than a day - i.e. an effectively
# fresh database - AND the only dependent view is the known, recreatable
# `trackers` view) and only then drops+recreates dependent views. Any database
# with real history, or any fresh production database with unrecognised
# dependent views it doesn't know how to safely recreate, takes the narrow
# (integer, smaller MULTIPLIER) path instead, which needs no type change and
# therefore never touches dependent views at all.
#
# The narrow path's own limit (protocol_id and master_id must together stay
# within int4 range) is enforced up front by check_protocol_ids_below_multiplier!
# and check_masters_fit_within_narrow_range!, which raise a clear, actionable
# error rather than letting a database already too close to the ceiling
# silently overflow on some future INSERT.
#
# Because development/test is exactly the environment used to regenerate the
# checked-in db/structure.sql (see repo conventions), this means freshly
# created databases (which load schema from structure.sql, never running this
# migration's Ruby at all) get the wide/bigint schema, while databases
# upgrading via `db:migrate` with real pre-existing history get the narrow
# schema - without needing two different files or manual intervention.
#
# trackers_instead_of_insert and trackers_instead_of_update (both defined in
# 20260304120000) pre-compute their own tracker_id guess (from trackers_id_seq
# or an existing group lookup) and explicitly insert it - but this migration's
# tracker_history-level trigger then overwrites the actual stored value with
# the deterministic formula regardless. Left unchanged, `NEW.id` (what Rails
# receives as the new Tracker's id) would keep reflecting the function's own
# stale guess rather than what was actually stored, so both functions are
# redefined here to stop trusting their own guess and instead read back
# whatever tracker_history_assign_tracker_id actually decided, via
# `RETURNING ... INTO`.
#
# A tracker_history row is meaningless without a master_id and protocol_id (it
# can never be grouped or displayed, and the tracker_id formula depends on
# both), so this migration enforces NOT NULL on those columns. Before doing
# so, check_for_null_group_columns! verifies no such rows already exist,
# raising a clear, actionable error naming the offending ids instead of
# letting a later ALTER COLUMN statement fail with a bare constraint
# violation.
#
# Fixes: #1309
class AssignTrackerIdDeterministicallyOnTrackerHistory < ActiveRecord::Migration[7.1]
  NARROW_MULTIPLIER = 1_000
  WIDE_MULTIPLIER = 1_000_000

  def up
    check_for_null_group_columns!

    # A tracker_history row without a master_id or protocol_id cannot be
    # meaningfully grouped (SQL's `NULL = NULL` is unknown, not true) and the
    # tracker_id formula below depends on both being present.
    execute <<~SQL
      ALTER TABLE tracker_history ALTER COLUMN master_id SET NOT NULL;
      ALTER TABLE tracker_history ALTER COLUMN protocol_id SET NOT NULL;
    SQL

    multiplier = if use_wide_tracker_id?
                   WIDE_MULTIPLIER
                 else
                   check_masters_fit_within_narrow_range!(NARROW_MULTIPLIER)
                   NARROW_MULTIPLIER
                 end
    check_protocol_ids_below_multiplier!(multiplier)

    widen_tracker_id_and_recreate_dependent_views! if multiplier == WIDE_MULTIPLIER

    create_tracker_id_trigger!(multiplier)
    redefine_trackers_view_triggers_to_read_back_tracker_id!

    # One-time recompute of every existing row to the new deterministic
    # scheme - this replaces both the old sequence-derived values and any
    # legacy NULLs left by the original bug in a single pass.
    execute <<~SQL
      UPDATE tracker_history SET tracker_id = master_id::bigint * #{multiplier} + protocol_id;
    SQL

    # Final backstop: tracker_id can never be NULL, independent of trigger
    # state (a disabled trigger, session_replication_role = 'replica', etc).
    execute <<~SQL
      ALTER TABLE tracker_history ALTER COLUMN tracker_id SET NOT NULL;
    SQL

    execute <<~SQL
      ALTER TABLE protocols ADD CONSTRAINT protocols_id_below_tracker_id_multiplier CHECK (id < #{multiplier});
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE protocols DROP CONSTRAINT IF EXISTS protocols_id_below_tracker_id_multiplier;
    SQL

    execute <<~SQL
      ALTER TABLE tracker_history ALTER COLUMN tracker_id DROP NOT NULL;
    SQL

    execute <<~SQL
      DROP TRIGGER IF EXISTS tracker_history_assign_tracker_id_trigger ON tracker_history;
      DROP FUNCTION IF EXISTS tracker_history_assign_tracker_id();
    SQL

    restore_original_trackers_view_triggers!

    # tracker_id's type is deliberately left as-is (bigint, if this database
    # took the wide path) rather than narrowed back to integer: narrowing
    # requires every existing value to already fit in the int4 range, which
    # cannot be guaranteed (and fails loudly with a plain overflow error if
    # not) - bigint is a strict superset of integer, so leaving it wide is
    # always safe, just not a byte-for-byte reversal.

    execute <<~SQL
      ALTER TABLE tracker_history ALTER COLUMN master_id DROP NOT NULL;
      ALTER TABLE tracker_history ALTER COLUMN protocol_id DROP NOT NULL;
    SQL
  end

  private

  # A tracker_history row without a master_id or protocol_id can never be
  # grouped or displayed, so it must never exist. Raise a clear, actionable
  # error naming the offending rows rather than letting the later
  # `ALTER COLUMN ... SET NOT NULL` fail with a bare constraint violation.
  def check_for_null_group_columns!
    count = execute(<<~SQL).first['count'].to_i
      SELECT COUNT(*) FROM tracker_history WHERE master_id IS NULL OR protocol_id IS NULL;
    SQL
    return if count.zero?

    sample_ids = execute(<<~SQL).map { |row| row['id'] }
      SELECT id FROM tracker_history
      WHERE master_id IS NULL OR protocol_id IS NULL
      ORDER BY id
      LIMIT 20;
    SQL

    raise "Cannot enforce NOT NULL on tracker_history.master_id/protocol_id: found #{count} row(s) with a " \
          'NULL master_id or protocol_id. A tracker_history row without both is not a valid entry and must ' \
          'be resolved manually before this migration can proceed. Offending tracker_history id(s) ' \
          "(showing up to 20 of #{count}): #{sample_ids.join(', ')}."
  end

  # On the narrow (integer) path, tracker_id = master_id::bigint * multiplier + protocol_id is stored back
  # into a plain int4 column (max 2_147_483_647). Unlike the wide path, this can never be widened later
  # without hitting the same dependent-view block this migration exists to avoid, so a database already too
  # close to the ceiling must be caught now, loudly, rather than left to overflow silently on some future
  # INSERT once master_id crosses the threshold.
  def check_masters_fit_within_narrow_range!(multiplier)
    max_safe_master_id = ((2**31) - 1 - (multiplier - 1)) / multiplier
    max_master_id = execute('SELECT MAX(id) AS max_id FROM masters;').first['max_id'].to_i
    return if max_master_id <= max_safe_master_id

    raise 'Cannot use the narrow (integer) tracker_id scheme: masters.id ' \
          "(max #{max_master_id}) already exceeds the safe range for multiplier #{multiplier} " \
          "(max #{max_safe_master_id}). This database has too much history to widen tracker_id " \
          'automatically - dependent views must be dropped and recreated manually first as part of a ' \
          'planned, scheduled migration.'
  end

  # protocol_id is added to master_id * multiplier, so any protocol_id >= multiplier would collide with
  # another master/protocol group's tracker_id (e.g. master 1/protocol 1000 == master 2/protocol 0 under
  # multiplier 1000), reintroducing the exact cross-contamination bug this migration fixes. Checked up front
  # - like check_for_null_group_columns! - rather than left to surface as a bare CHECK violation after the
  # trigger and one-time UPDATE have already run.
  def check_protocol_ids_below_multiplier!(multiplier)
    max_protocol_id = execute('SELECT MAX(id) AS max_id FROM protocols;').first['max_id'].to_i
    return if max_protocol_id < multiplier

    raise "Cannot enforce protocols.id < #{multiplier}: found a protocols.id of #{max_protocol_id}, which " \
          'would collide with another master/protocol group under the tracker_id formula. This must be ' \
          'resolved manually before this migration can proceed.'
  end

  # Widening tracker_id to bigint is only safe to attempt where dropping and
  # recreating dependent views has no real consequence: development/test
  # (also how db/structure.sql gets regenerated - see header comment), or a
  # production database with no master records older than a day (effectively
  # unused so far) AND no unrecognised dependent views it doesn't already know
  # how to safely recreate (see widen_tracker_id_and_recreate_dependent_views!).
  # Any database with real history, or any fresh production database that
  # would otherwise lose an unknown view, takes the narrow path instead, which
  # needs no type change at all.
  def use_wide_tracker_id?
    return true if Rails.env.development? || Rails.env.test?
    return false if old_master_records_exist?

    # Fresh production database: only safe to auto-widen if there are no unrecognised dependent views
    # that would otherwise be silently dropped (see widen_tracker_id_and_recreate_dependent_views!) -
    # fall back to the narrow path if there's anything here we don't already know how to recreate.
    dependent_view_names.all? { |_schema, name| name == 'trackers' }
  end

  def old_master_records_exist?
    execute(<<~SQL).first['exists'] == 't'
      SELECT EXISTS (SELECT 1 FROM masters WHERE created_at < now() - interval '1 day') AS exists;
    SQL
  end

  # Every view depending on tracker_history.tracker_id must be dropped before
  # its type can change - Postgres refuses ALTER COLUMN ... TYPE otherwise.
  # The `trackers` view is recreated in full immediately afterward (we know
  # its exact definition and triggers). Any other dependent view - typically
  # an admin-configured dynamic-model view - is dropped without being
  # recreated; this is only acceptable because this path is restricted to
  # development/test/fresh databases (see use_wide_tracker_id?).
  def widen_tracker_id_and_recreate_dependent_views!
    views = dependent_view_names
    extra_views = views.reject { |_schema, name| name == 'trackers' }

    views.each do |schema, name|
      execute "DROP VIEW IF EXISTS #{schema}.#{name} CASCADE;"
    end

    execute 'ALTER TABLE tracker_history ALTER COLUMN tracker_id TYPE bigint;'

    recreate_trackers_view!

    return if extra_views.empty?

    names = extra_views.map { |schema, name| "#{schema}.#{name}" }.join(', ')
    warn 'AssignTrackerIdDeterministicallyOnTrackerHistory: dropped view(s) not recreated by this ' \
         "migration (development/test/fresh databases only): #{names}. These are typically dynamic-model-" \
         'generated views - recreate them via the admin panel or an app-specific rake task if needed locally.'
  end

  def dependent_view_names
    execute(<<~SQL).map { |row| [row['view_schema'], row['view_name']] }
      SELECT DISTINCT view_schema, view_name
      FROM information_schema.view_column_usage
      WHERE table_schema = current_schema() AND table_name = 'tracker_history' AND column_name = 'tracker_id';
    SQL
  end

  def recreate_trackers_view!
    execute <<~SQL
      CREATE VIEW trackers AS
      SELECT DISTINCT ON (master_id, protocol_id) tracker_id AS id,
        master_id, protocol_id, event_date, user_id, notes, created_at, updated_at,
        sub_process_id, protocol_event_id, item_id, item_type
      FROM tracker_history th
      ORDER BY master_id, protocol_id, (event_date)::date DESC NULLS LAST, th.id DESC;

      CREATE TRIGGER trackers_insert_trigger INSTEAD OF INSERT ON trackers
        FOR EACH ROW EXECUTE FUNCTION trackers_instead_of_insert();
      CREATE TRIGGER trackers_update_trigger INSTEAD OF UPDATE ON trackers
        FOR EACH ROW EXECUTE FUNCTION trackers_instead_of_update();
      CREATE TRIGGER trackers_delete_trigger INSTEAD OF DELETE ON trackers
        FOR EACH ROW EXECUTE FUNCTION trackers_instead_of_delete();
    SQL
  end

  def create_tracker_id_trigger!(multiplier)
    execute <<~SQL
      CREATE OR REPLACE FUNCTION tracker_history_assign_tracker_id() RETURNS trigger AS $$
      BEGIN
        NEW.tracker_id := NEW.master_id::bigint * #{multiplier} + NEW.protocol_id;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      DROP TRIGGER IF EXISTS tracker_history_assign_tracker_id_trigger ON tracker_history;
      CREATE TRIGGER tracker_history_assign_tracker_id_trigger
        BEFORE INSERT OR UPDATE ON tracker_history
        FOR EACH ROW EXECUTE FUNCTION tracker_history_assign_tracker_id();
    SQL
  end

  # trackers_instead_of_insert/update (20260304120000) each pre-compute their
  # own tracker_id guess and explicitly INSERT it - but tracker_history's own
  # BEFORE INSERT trigger (created above) then overwrites the actually-stored
  # value with the deterministic formula regardless of what was supplied.
  # Redefine both to stop trusting their own guess and instead read back
  # whatever was actually stored via RETURNING, so NEW.id (what Rails sees as
  # the new/updated Tracker's id) always matches the real stored tracker_id.
  def redefine_trackers_view_triggers_to_read_back_tracker_id!
    execute <<~SQL
      CREATE OR REPLACE FUNCTION trackers_instead_of_insert() RETURNS trigger AS $$
      DECLARE
        inserted_tracker_id BIGINT;
      BEGIN
        INSERT INTO tracker_history
          (master_id, protocol_id,
           protocol_event_id, event_date, sub_process_id, notes,
           item_id, item_type,
           created_at, updated_at, user_id)
        VALUES
          (NEW.master_id, NEW.protocol_id,
           NEW.protocol_event_id, NEW.event_date, NEW.sub_process_id, NEW.notes,
           NEW.item_id, NEW.item_type,
           COALESCE(NEW.created_at, now()), COALESCE(NEW.updated_at, now()), NEW.user_id)
        RETURNING tracker_id INTO inserted_tracker_id;

        NEW.id := inserted_tracker_id;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE OR REPLACE FUNCTION trackers_instead_of_update() RETURNS trigger AS $$
      DECLARE
        inserted_tracker_id BIGINT;
      BEGIN
        INSERT INTO tracker_history
          (master_id, protocol_id,
           protocol_event_id, event_date, sub_process_id, notes,
           item_id, item_type,
           created_at, updated_at, user_id)
        VALUES
          (NEW.master_id, NEW.protocol_id,
           NEW.protocol_event_id, NEW.event_date, NEW.sub_process_id, NEW.notes,
           NEW.item_id, NEW.item_type,
           COALESCE(NEW.created_at, now()), COALESCE(NEW.updated_at, now()), NEW.user_id)
        RETURNING tracker_id INTO inserted_tracker_id;

        NEW.id := inserted_tracker_id;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
  end

  # Restores trackers_instead_of_insert/update to their exact original
  # (20260304120000, pre-#1309) bodies, which pre-compute and explicitly
  # insert their own tracker_id guess. Safe again once tracker_history's own
  # assignment trigger (dropped earlier in #down) no longer overwrites it.
  def restore_original_trackers_view_triggers!
    execute <<~SQL
      CREATE OR REPLACE FUNCTION trackers_instead_of_insert() RETURNS trigger AS $$
      DECLARE
        existing_tracker_id INTEGER;
      BEGIN
        SELECT tracker_id INTO existing_tracker_id
        FROM tracker_history
        WHERE master_id = NEW.master_id AND protocol_id = NEW.protocol_id
        LIMIT 1;

        IF existing_tracker_id IS NULL THEN
          existing_tracker_id := nextval('trackers_id_seq');
        END IF;

        INSERT INTO tracker_history
          (tracker_id, master_id, protocol_id,
           protocol_event_id, event_date, sub_process_id, notes,
           item_id, item_type,
           created_at, updated_at, user_id)
        VALUES
          (existing_tracker_id, NEW.master_id, NEW.protocol_id,
           NEW.protocol_event_id, NEW.event_date, NEW.sub_process_id, NEW.notes,
           NEW.item_id, NEW.item_type,
           COALESCE(NEW.created_at, now()), COALESCE(NEW.updated_at, now()), NEW.user_id);

        NEW.id := existing_tracker_id;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE OR REPLACE FUNCTION trackers_instead_of_update() RETURNS trigger AS $$
      BEGIN
        INSERT INTO tracker_history
          (tracker_id, master_id, protocol_id,
           protocol_event_id, event_date, sub_process_id, notes,
           item_id, item_type,
           created_at, updated_at, user_id)
        VALUES
          (OLD.id, NEW.master_id, NEW.protocol_id,
           NEW.protocol_event_id, NEW.event_date, NEW.sub_process_id, NEW.notes,
           NEW.item_id, NEW.item_type,
           COALESCE(NEW.created_at, now()), COALESCE(NEW.updated_at, now()), NEW.user_id);

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
  end
end
