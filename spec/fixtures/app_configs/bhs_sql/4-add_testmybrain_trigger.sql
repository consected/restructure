SET SEARCH_PATH=ml_app;

DROP FUNCTION IF EXISTS activity_log_bhs_assignment_insert_testmybrain() cascade;
DROP FUNCTION IF EXISTS activity_log_bhs_assignment_insert_defaults() cascade;

CREATE FUNCTION activity_log_bhs_assignment_insert_defaults() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        DECLARE
          found_bhs RECORD;
          found_phone RECORD;
        BEGIN

            -- if there is no player contact phone set, try and set it
            -- in case the sync from Zeus to Elaine happened between the time the
            -- user opened the new form (with an empty drop down) and now.
            -- This avoids missing the population of this field
            IF NEW.select_record_from_player_contact_phones IS NULL THEN
              SELECT * FROM player_contacts
              INTO found_phone
              WHERE master_id = NEW.master_id AND rec_type = 'phone'
              ORDER BY rank desc
              LIMIT 1;

              IF found_phone.data is not null THEN
                NEW.select_record_from_player_contact_phones := found_phone.data;
              END IF;

            END IF;


            -- Generate the testmybrain URL from the BHS ID
            select * from bhs_assignments
            into found_bhs
            where master_id = NEW.master_id
            limit 1;


            IF found_bhs.bhs_id is not null THEN
              NEW.results_link := ('https://testmybrain.org/fphs/get_id.php?id=' || found_bhs.bhs_id::varchar);
            END IF;
            RETURN NEW;
        END;
    $$;

CREATE TRIGGER activity_log_bhs_assignment_insert_defaults BEFORE INSERT ON activity_log_bhs_assignments FOR EACH ROW EXECUTE PROCEDURE activity_log_bhs_assignment_insert_defaults();
