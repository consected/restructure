SET search_path=ml_app;
create table sync_statuses
  (
    id serial,
    from_db varchar,
    from_master_id integer,
    to_db varchar,
    to_master_id integer,
    select_status varchar default 'new',
    created_at timestamp without time zone,
    updated_at timestamp without time zone
  )
;
