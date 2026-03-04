# frozen_string_literal: true

# Replace the trackers table with a database view derived from tracker_history.
# This ensures the ordering rule for "latest tracker entry per protocol" exists
# in exactly one place (the view definition), resolving the dual-ordering
# inconsistency between the DB trigger and the Ruby constant.
#
# Fixes: #830 (tracker history out of order)
#        #939 (panel shows repeated/inconsistent items)
# See:   https://github.com/consected/restructure/issues/941
class ReplaceTrackersTableWithView < ActiveRecord::Migration[7.1]
  def up
    # Step 1: Add composite index on tracker_history for efficient DISTINCT ON
    execute <<~SQL
      CREATE INDEX IF NOT EXISTS index_tracker_history_on_latest_lookup
        ON tracker_history (master_id, protocol_id, (event_date::date) DESC NULLS LAST, id DESC);
    SQL

    # Step 2: Drop FK constraints from tracker_history → trackers
    execute <<~SQL
      ALTER TABLE tracker_history DROP CONSTRAINT IF EXISTS fk_rails_6e050927c2;
      ALTER TABLE tracker_history DROP CONSTRAINT IF EXISTS unique_master_protocol_tracker_id;
    SQL

    # Step 3: Drop all 5 triggers
    execute <<~SQL
      -- On trackers table
      DROP TRIGGER IF EXISTS tracker_upsert ON trackers;
      DROP TRIGGER IF EXISTS tracker_history_insert ON trackers;
      DROP TRIGGER IF EXISTS tracker_history_update ON trackers;

      -- On tracker_history table
      DROP TRIGGER IF EXISTS tracker_history_update ON tracker_history;
      DROP TRIGGER IF EXISTS tracker_record_delete ON tracker_history;
    SQL

    # Step 4: Rename trackers table → trackers_old (preserve for one release cycle)
    execute <<~SQL
      ALTER TABLE trackers RENAME TO trackers_old;
    SQL

    # Step 5: Detach the sequence from the old table so it persists independently
    execute <<~SQL
      ALTER SEQUENCE trackers_id_seq OWNED BY NONE;
    SQL

    # Step 6: Create the trackers view
    # Canonical ordering rule: event_date (date only) DESC, then id DESC
    # DISTINCT ON picks the latest tracker_history entry per (master_id, protocol_id)
    execute <<~SQL
      CREATE OR REPLACE VIEW trackers AS
      SELECT DISTINCT ON (th.master_id, th.protocol_id)
        th.tracker_id AS id,
        th.master_id,
        th.protocol_id,
        th.event_date,
        th.user_id,
        th.notes,
        th.created_at,
        th.updated_at,
        th.sub_process_id,
        th.protocol_event_id,
        th.item_id,
        th.item_type
      FROM tracker_history th
      ORDER BY th.master_id, th.protocol_id,
               th.event_date::date DESC NULLS LAST,
               th.id DESC;
    SQL

    # Step 7: Create INSTEAD OF INSERT trigger to route inserts to tracker_history
    execute <<~SQL
      CREATE OR REPLACE FUNCTION trackers_instead_of_insert() RETURNS trigger AS $$
      DECLARE
        existing_tracker_id INTEGER;
      BEGIN
        -- Find existing tracker_id for this master/protocol pair
        SELECT tracker_id INTO existing_tracker_id
        FROM tracker_history
        WHERE master_id = NEW.master_id AND protocol_id = NEW.protocol_id
        LIMIT 1;

        -- If no existing group, use the sequence
        IF existing_tracker_id IS NULL THEN
          existing_tracker_id := nextval('trackers_id_seq');
        END IF;

        -- Always insert into tracker_history (the single source of truth)
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

        -- Set the id on NEW so Rails gets it back via RETURNING
        NEW.id := existing_tracker_id;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER trackers_insert_trigger
        INSTEAD OF INSERT ON trackers
        FOR EACH ROW EXECUTE FUNCTION trackers_instead_of_insert();
    SQL

    # Step 8: Create INSTEAD OF UPDATE trigger to route updates to tracker_history
    # When a tracker is "updated" via the view (e.g., track_record_update),
    # we insert a new tracker_history row with the updated values.
    # This maintains backward compatibility with code that calls tracker.save
    # on a persisted record.
    execute <<~SQL
      CREATE OR REPLACE FUNCTION trackers_instead_of_update() RETURNS trigger AS $$
      BEGIN
        -- Insert a new tracker_history row with the updated values
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

      CREATE TRIGGER trackers_update_trigger
        INSTEAD OF UPDATE ON trackers
        FOR EACH ROW EXECUTE FUNCTION trackers_instead_of_update();
    SQL

    # Step 9: Create INSTEAD OF DELETE trigger to route deletes to tracker_history
    # Deleting a row from the view means deleting all tracker_history rows
    # for the same tracker group (identified by tracker_id).
    execute <<~SQL
      CREATE OR REPLACE FUNCTION trackers_instead_of_delete() RETURNS trigger AS $$
      BEGIN
        DELETE FROM tracker_history
        WHERE tracker_id = OLD.id;

        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER trackers_delete_trigger
        INSTEAD OF DELETE ON trackers
        FOR EACH ROW EXECUTE FUNCTION trackers_instead_of_delete();
    SQL

    # Step 10: Drop old trigger functions (no longer needed)
    execute <<~SQL
      DROP FUNCTION IF EXISTS tracker_upsert();
      DROP FUNCTION IF EXISTS log_tracker_update();
      DROP FUNCTION IF EXISTS handle_tracker_history_update();
      DROP FUNCTION IF EXISTS handle_delete();
    SQL
  end

  def down
    # Drop the view and its triggers
    execute <<~SQL
      DROP TRIGGER IF EXISTS trackers_delete_trigger ON trackers;
      DROP TRIGGER IF EXISTS trackers_update_trigger ON trackers;
      DROP TRIGGER IF EXISTS trackers_insert_trigger ON trackers;
      DROP VIEW IF EXISTS trackers;
      DROP FUNCTION IF EXISTS trackers_instead_of_delete();
      DROP FUNCTION IF EXISTS trackers_instead_of_update();
      DROP FUNCTION IF EXISTS trackers_instead_of_insert();
    SQL

    # Rename trackers_old back to trackers
    execute <<~SQL
      ALTER TABLE trackers_old RENAME TO trackers;
      ALTER SEQUENCE trackers_id_seq OWNED BY trackers.id;
    SQL

    # Recreate handle_delete()
    execute <<~SQL
      CREATE OR REPLACE FUNCTION handle_delete() RETURNS trigger
      LANGUAGE plpgsql
      AS $$
        DECLARE
          latest_tracker tracker_history%ROWTYPE;
        BEGIN
          SELECT * INTO latest_tracker
            FROM tracker_history
            WHERE tracker_id = OLD.tracker_id
            ORDER BY event_date DESC NULLS last, updated_at DESC NULLS last LIMIT 1;

          IF NOT FOUND THEN
            DELETE FROM trackers WHERE trackers.id = OLD.tracker_id;
          ELSE
            UPDATE trackers
              SET
                event_date = latest_tracker.event_date,
                sub_process_id = latest_tracker.sub_process_id,
                protocol_event_id = latest_tracker.protocol_event_id,
                item_id = latest_tracker.item_id,
                item_type = latest_tracker.item_type,
                updated_at = latest_tracker.updated_at,
                notes = latest_tracker.notes,
                user_id = latest_tracker.user_id
              WHERE trackers.id = OLD.tracker_id;
          END IF;

          RETURN OLD;
        END
      $$;
    SQL

    # Recreate handle_tracker_history_update()
    execute <<~SQL
      CREATE OR REPLACE FUNCTION handle_tracker_history_update() RETURNS trigger
      LANGUAGE plpgsql
      AS $$
      BEGIN
        DELETE FROM tracker_history WHERE id = OLD.id;
        INSERT INTO trackers
          (master_id, protocol_id,
           protocol_event_id, event_date, sub_process_id, notes,
           item_id, item_type,
           created_at, updated_at, user_id)
          SELECT NEW.master_id, NEW.protocol_id,
             NEW.protocol_event_id, NEW.event_date,
             NEW.sub_process_id, NEW.notes,
             NEW.item_id, NEW.item_type,
             NEW.created_at, NEW.updated_at, NEW.user_id;
        RETURN NULL;
      END;
      $$;
    SQL

    # Recreate log_tracker_update()
    execute <<~SQL
      CREATE OR REPLACE FUNCTION log_tracker_update() RETURNS trigger
      LANGUAGE plpgsql
      AS $$
        BEGIN
          PERFORM * from tracker_history
            WHERE
              master_id = NEW.master_id
              AND protocol_id = NEW.protocol_id
              AND coalesce(protocol_event_id,-1) = coalesce(NEW.protocol_event_id,-1)
              AND coalesce(event_date, '1900-01-01'::date)::date = coalesce(NEW.event_date, '1900-01-01')::date
              AND sub_process_id = NEW.sub_process_id
              AND coalesce(notes,'') = coalesce(NEW.notes,'')
              AND coalesce(item_id,-1) = coalesce(NEW.item_id,-1)
              AND coalesce(item_type,'') = coalesce(NEW.item_type,'')
              AND updated_at::timestamp = NEW.updated_at::timestamp
              AND coalesce(user_id,-1) = coalesce(NEW.user_id,-1);

            IF NOT FOUND THEN
              INSERT INTO tracker_history
                  (tracker_id, master_id, protocol_id,
                   protocol_event_id, event_date, sub_process_id, notes,
                   item_id, item_type,
                   created_at, updated_at, user_id)
                  SELECT NEW.id, NEW.master_id, NEW.protocol_id,
                     NEW.protocol_event_id, NEW.event_date,
                     NEW.sub_process_id, NEW.notes,
                     NEW.item_id, NEW.item_type,
                     NEW.created_at, NEW.updated_at, NEW.user_id;
            END IF;

            RETURN NEW;
        END;
      $$;
    SQL

    # Recreate tracker_upsert()
    execute <<~SQL
      CREATE OR REPLACE FUNCTION tracker_upsert() RETURNS trigger
      LANGUAGE plpgsql
      AS $$
        DECLARE
          latest_tracker trackers%ROWTYPE;
        BEGIN
          SELECT * into latest_tracker
            FROM trackers
            WHERE
              master_id = NEW.master_id
              AND protocol_id = NEW.protocol_id
            ORDER BY
              event_date DESC NULLS LAST, updated_at DESC NULLS LAST
            LIMIT 1;

          IF NOT FOUND THEN
            RETURN NEW;
          ELSE
            IF latest_tracker.event_date > NEW.event_date OR
                latest_tracker.event_date = NEW.event_date AND latest_tracker.updated_at > NEW.updated_at
                THEN
              INSERT INTO tracker_history (
                  tracker_id, master_id, protocol_id,
                  protocol_event_id, event_date, sub_process_id, notes,
                  item_id, item_type,
                  created_at, updated_at, user_id
                )
                SELECT
                  latest_tracker.id, NEW.master_id, NEW.protocol_id,
                  NEW.protocol_event_id, NEW.event_date,
                  NEW.sub_process_id, NEW.notes,
                  NEW.item_id, NEW.item_type,
                  NEW.created_at, NEW.updated_at, NEW.user_id;

              RETURN NULL;
            ELSE
              UPDATE trackers SET
                master_id = NEW.master_id,
                protocol_id = NEW.protocol_id,
                protocol_event_id = NEW.protocol_event_id,
                event_date = NEW.event_date,
                sub_process_id = NEW.sub_process_id,
                notes = NEW.notes,
                item_id = NEW.item_id,
                item_type = NEW.item_type,
                updated_at = NEW.updated_at,
                user_id = NEW.user_id
              WHERE master_id = NEW.master_id AND
                protocol_id = NEW.protocol_id;
              RETURN NULL;
            END IF;
          END IF;
        END;
      $$;
    SQL

    # Recreate triggers on trackers
    execute <<~SQL
      CREATE TRIGGER tracker_upsert BEFORE INSERT ON trackers
        FOR EACH ROW EXECUTE FUNCTION tracker_upsert();

      CREATE TRIGGER tracker_history_insert AFTER INSERT ON trackers
        FOR EACH ROW EXECUTE FUNCTION log_tracker_update();

      CREATE TRIGGER tracker_history_update AFTER UPDATE ON trackers
        FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE FUNCTION log_tracker_update();
    SQL

    # Recreate triggers on tracker_history
    execute <<~SQL
      CREATE TRIGGER tracker_history_update BEFORE UPDATE ON tracker_history
        FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE FUNCTION handle_tracker_history_update();

      CREATE TRIGGER tracker_record_delete AFTER DELETE ON tracker_history
        FOR EACH ROW EXECUTE FUNCTION handle_delete();
    SQL

    # Recreate FK constraints
    execute <<~SQL
      ALTER TABLE tracker_history
        ADD CONSTRAINT fk_rails_6e050927c2 FOREIGN KEY (tracker_id) REFERENCES trackers(id);

      ALTER TABLE tracker_history
        ADD CONSTRAINT unique_master_protocol_tracker_id
        FOREIGN KEY (master_id, protocol_id, tracker_id) REFERENCES trackers(master_id, protocol_id, id);
    SQL

    # Drop the composite index
    execute <<~SQL
      DROP INDEX IF EXISTS index_tracker_history_on_latest_lookup;
    SQL
  end
end
