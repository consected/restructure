-- sync_statuses table used to record attempted and completed synchronization of master record data from
-- AWS DB back to Zeus databases

create table if not exists ml_app.sync_statuses
  (
    id serial,
    from_db varchar,
    from_master_id integer,
    to_db varchar,
    to_master_id integer,
    external_id varchar,
    external_type varchar,
    event varchar,
    select_status varchar default 'new',
    record_updated_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
  )
;

-- alter table ml_app.sync_statuses
-- add column record_updated_at timestamp without time zone;

GRANT ALL ON ml_app.sync_statuses TO fphs;
GRANT SELECT ON ml_app.sync_statuses TO fphsusr;
GRANT SELECT ON ml_app.sync_statuses TO fphsetl;
GRANT SELECT ON ml_app.sync_statuses TO fphsadm;
