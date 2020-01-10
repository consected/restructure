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


REVOKE ALL ON SCHEMA ml_app FROM fphs;
GRANT ALL ON SCHEMA ml_app TO fphs;
GRANT USAGE ON SCHEMA ml_app TO fphsadm;
GRANT USAGE ON SCHEMA ml_app TO fphsusr;
GRANT USAGE ON SCHEMA ml_app TO fphsetl;


GRANT ALL ON ALL TABLES IN SCHEMA ml_app TO fphs;
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphsusr;
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphsetl;
GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON ALL TABLES IN SCHEMA ml_app TO fphsadm;

GRANT ALL ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphsusr;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphsetl;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphsadm;


DO
$body$
BEGIN

IF EXISTS (
   SELECT *
   FROM   pg_catalog.pg_roles
   WHERE  rolname = 'fphsrailsapp') THEN

   GRANT USAGE ON SCHEMA ml_app TO fphsrailsapp;
   GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphsrailsapp;
   GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphsrailsapp;
END IF;


END
$body$;
