set search_path=bulk_msg,ml_app;

      BEGIN;

ALTER TABLE zeus_short_link_history
alter column for_item_id type integer using for_item_id::integer;


ALTER TABLE zeus_short_links
alter column for_item_id type integer using for_item_id::integer;


commit;
