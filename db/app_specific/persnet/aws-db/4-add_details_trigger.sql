SET SEARCH_PATH=persnet_schema,ml_app;

DROP FUNCTION IF EXISTS activity_log_persnet_assignment_insert_persnet_schema() cascade;
DROP FUNCTION IF EXISTS activity_log_persnet_assignment_insert_defaults() cascade;

CREATE FUNCTION activity_log_persnet_assignment_insert_defaults() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        DECLARE
          found_persnet RECORD;
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


            -- Generate the persnet_schema URL from the persnet ID
            -- select * from persnet_assignments
            -- into found_persnet
            -- where master_id = NEW.master_id
            -- limit 1;


            -- IF found_persnet.persnet_id is not null THEN
            --   NEW.results_link := ('https://persnet_schema.org/fphs/get_id.php?id=' || found_persnet.persnet_id::varchar);
            -- END IF;
            RETURN NEW;
        END;
    $$;

CREATE TRIGGER activity_log_persnet_assignment_insert_defaults BEFORE INSERT ON activity_log_persnet_assignments FOR EACH ROW EXECUTE PROCEDURE activity_log_persnet_assignment_insert_defaults();
