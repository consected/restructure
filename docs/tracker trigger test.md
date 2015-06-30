Testing a Trigger on Tracker for Chronological Logging
===================


    CREATE OR REPLACE FUNCTION log_tracker_update() RETURNS TRIGGER AS $hist_update$
        BEGIN
            INSERT INTO tracker_history 
                (tracker_id, master_id, protocol_id, 
                 event, event_date, c_method,
                 outcome, outcome_date, notes,
                 created_at, updated_at, user_id)
                 
            SELECT NEW.id, NEW.master_id, NEW.protocol_id, 
                   NEW.event, NEW.event_date, NEW.c_method, 
                   NEW.outcome, NEW.outcome_date, NEW.notes, 
                   NEW.created_at, NEW.updated_at, NEW.user_id  ;
            RETURN NEW;
        END;
    $hist_update$ LANGUAGE plpgsql;

    DROP TRIGGER tracker_history_update ON trackers;

    CREATE TRIGGER tracker_history_update
        AFTER UPDATE ON trackers
        FOR EACH ROW
        WHEN (OLD.* IS DISTINCT FROM NEW.*)
        EXECUTE PROCEDURE log_tracker_update();

    DROP TRIGGER tracker_history_insert ON trackers;
    CREATE TRIGGER tracker_history_insert
        AFTER INSERT ON trackers
        FOR EACH ROW
        EXECUTE PROCEDURE log_tracker_update();
