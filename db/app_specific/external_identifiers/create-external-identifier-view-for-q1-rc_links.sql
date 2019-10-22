create view
ml_app.q1_rc_links as
select id, master_id, link q1_rc_link_ext_id, null::timestamp created_at, null::timestamp  updated_at, null::integer user_id
from q1.rc_links;


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
