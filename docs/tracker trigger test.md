Set Sequence on any manually populated tables
====
This is required after using dump to populate data. It seems the sequences aren't updated. Do not use if there is no data in the tables.

    SELECT setval('player_infos_id_seq', (SELECT MAX(id) FROM player_infos));
    SELECT setval('pro_infos_id_seq', (SELECT MAX(id) FROM pro_infos));
    SELECT setval('masters_id_seq', (SELECT MAX(id) FROM masters));
    SELECT setval('addresses_id_seq', (SELECT MAX(id) FROM addresses));
    SELECT setval('player_contacts_id_seq', (SELECT MAX(id) FROM player_contacts));
    SELECT setval('scantrons_id_seq', (SELECT MAX(id) FROM scantrons));

Trigger on Tracker for Chronological Logging
===================


    CREATE OR REPLACE FUNCTION log_tracker_update() RETURNS TRIGGER AS $hist_update$
        BEGIN
            INSERT INTO tracker_history 
                (tracker_id, master_id, protocol_id, 
                 protocol_event_id, event_date, sub_process_id, notes,
                 created_at, updated_at, user_id)
                 
            SELECT NEW.id, NEW.master_id, NEW.protocol_id, 
                   NEW.protocol_event_id, NEW.event_date, 
                   NEW.sub_process_id, NEW.notes, 
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





Trigger on Masters table
====

    CREATE OR REPLACE FUNCTION update_master_with_pro_info() RETURNS TRIGGER AS $master_update$
        BEGIN
            UPDATE masters 
                set pro_info_id = NEW.id, pro_id = NEW.pro_id             
            WHERE masters.id = NEW.master_id;
            
            RETURN NEW;
        END;
    $master_update$ LANGUAGE plpgsql;

    DROP TRIGGER pro_info_update ON pro_infos;

    CREATE TRIGGER pro_info_update
        AFTER UPDATE ON pro_infos
        FOR EACH ROW
        WHEN (OLD.* IS DISTINCT FROM NEW.*)
        EXECUTE PROCEDURE update_master_with_pro_info();

    DROP TRIGGER pro_info_insert ON pro_infos;
    CREATE TRIGGER pro_info_insert
        AFTER INSERT ON pro_infos
        FOR EACH ROW
        EXECUTE PROCEDURE update_master_with_pro_info();


