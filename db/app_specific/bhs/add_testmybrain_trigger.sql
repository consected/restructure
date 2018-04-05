CREATE FUNCTION activity_log_bhs_assignment_insert_testmybrain() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        DECLARE
          found_bhs RECORD;
        BEGIN

            select * from bhs_assignments
            into found_bhs
            where master_id = NEW.master_id
            limit 1;


            IF found_bhs.bhs_id is not null THEN
              NEW.results_link := ('https://testmybrain.org?demotestid=' || found_bhs.bhs_id::varchar);
            END IF;
            RETURN NEW;
        END;
    $$;

CREATE TRIGGER activity_log_bhs_testmybrain BEFORE INSERT ON activity_log_bhs_assignments FOR EACH ROW EXECUTE PROCEDURE activity_log_bhs_assignment_insert_testmybrain();
