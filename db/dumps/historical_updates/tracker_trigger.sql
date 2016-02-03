drop trigger tracker_upsert on trackers;
drop function tracker_upsert();

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
