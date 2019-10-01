set search_path=bulk_msg,ml_app;

ALTER TABLE zeus_short_links
alter column clicks type integer USING clicks::integer,
alter column clicks set default 0;

ALTER TABLE zeus_short_link_history
alter column clicks type integer USING clicks::integer,
alter column clicks set default 0;

update zeus_short_links set clicks = 0 where clicks is null;
update zeus_short_link_history set clicks = 0 where clicks is null;
