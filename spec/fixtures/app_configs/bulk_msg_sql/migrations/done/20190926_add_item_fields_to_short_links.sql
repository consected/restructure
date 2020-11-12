set search_path=bulk_msg,ml_app;
CREATE or REPLACE FUNCTION log_zeus_short_link_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO zeus_short_link_history
            (
                master_id,
                domain,
                url,
                shortcode,
                clicks,
                next_check_date,
                for_item_type,
                for_item_id,
                user_id,
                created_at,
                updated_at,
                zeus_short_link_id
                )
            SELECT
                NEW.master_id,
                NEW.domain,
                NEW.url,
                NEW.shortcode,
                NEW.clicks,
                NEW.next_check_date,
                NEW.for_item_type,
                NEW.for_item_id,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

    ALTER TABLE zeus_short_link_history
    add column for_item_type varchar,
    add column for_item_id varchar;

    ALTER TABLE zeus_short_links
    add column for_item_type varchar,
    add column for_item_id varchar;
