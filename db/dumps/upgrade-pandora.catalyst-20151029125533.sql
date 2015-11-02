-- Script created @ 2015-10-29 12:55:33 -0400
set search_path=public;
begin

CREATE FUNCTION tracker_upsert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            if (select EXISTS(
                    select 1 from trackers where 
                    protocol_id  = NEW.protocol_id AND 
                    master_id = NEW.master_id
                    )
                ) then
                UPDATE trackers SET
                    master_id = NEW.master_id, 
                    protocol_id = NEW.protocol_id, 
                    protocol_event_id = NEW.protocol_event_id, 
                    event_date = NEW.event_date, 
                    sub_process_id = NEW.sub_process_id, 
                    notes = NEW.notes, 
                    item_id = NEW.item_id, 
                    item_type = NEW.item_type,
                    -- do not update created_at --
                    updated_at = NEW.updated_at, 
                    user_id = NEW.user_id
                WHERE master_id = NEW.master_id AND 
                    protocol_id = NEW.protocol_id
                ;
                RETURN NULL;
            end if;
            RETURN NEW;
        END;
    $$;


CREATE TRIGGER tracker_upsert BEFORE INSERT ON trackers FOR EACH ROW EXECUTE PROCEDURE tracker_upsert();


ALTER TABLE "dynamic_models" ADD "field_list" character varying;
ALTER TABLE "dynamic_models" ADD "result_order" character varying;

commit;
-- Run on 10/29