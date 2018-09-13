-- sync_statuses table used to record attempted and completed synchronization of master record data from
-- Zeus to external (AWS) databases
SET search_path=ml_app;
create table if not exists sync_statuses
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

GRANT ALL ON ml_app.sync_statuses TO fphs;
GRANT SELECT ON ml_app.sync_statuses TO fphsusr;
GRANT SELECT ON ml_app.sync_statuses TO fphsetl;
GRANT SELECT ON ml_app.sync_statuses TO fphsadm;
