SET SEARCH_PATH={{app_schema}},ml_app;

DROP FUNCTION IF EXISTS activity_log_{{app_name}}_assignment_insert_{{app_schema}}() cascade;
DROP FUNCTION IF EXISTS activity_log_{{app_name}}_assignment_insert_defaults() cascade;

CREATE FUNCTION activity_log_{{app_name}}_assignment_insert_defaults() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        DECLARE
          found_{{app_name}} RECORD;
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


            -- Generate the {{app_schema}} URL from the {{app_name}} ID
            -- select * from {{app_name}}_assignments
            -- into found_{{app_name}}
            -- where master_id = NEW.master_id
            -- limit 1;


            -- IF found_{{app_name}}.{{app_name}}_id is not null THEN
            --   NEW.results_link := ('https://{{app_schema}}.org/fphs/get_id.php?id=' || found_{{app_name}}.{{app_name}}_id::varchar);
            -- END IF;
            RETURN NEW;
        END;
    $$;

CREATE TRIGGER activity_log_{{app_name}}_assignment_insert_defaults BEFORE INSERT ON activity_log_{{app_name}}_assignments FOR EACH ROW EXECUTE PROCEDURE activity_log_{{app_name}}_assignment_insert_defaults();
