REVOKE ALL ON SCHEMA #{app_schema} FROM fphs;
GRANT ALL ON SCHEMA #{app_schema} TO fphs;
GRANT USAGE ON SCHEMA #{app_schema} TO fphsadm;
GRANT USAGE ON SCHEMA #{app_schema} TO fphsusr;
GRANT USAGE ON SCHEMA #{app_schema} TO fphsetl;


GRANT ALL ON ALL TABLES IN SCHEMA #{app_schema} TO fphs;
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA #{app_schema} TO fphsusr;
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA #{app_schema} TO fphsetl;
GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON ALL TABLES IN SCHEMA #{app_schema} TO fphsadm;

GRANT ALL ON ALL SEQUENCES IN SCHEMA #{app_schema} TO fphs;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA #{app_schema} TO fphsusr;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA #{app_schema} TO fphsetl;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA #{app_schema} TO fphsadm;


DO
$body$
BEGIN

IF EXISTS (
   SELECT *
   FROM   pg_catalog.pg_roles
   WHERE  rolname = 'fphsrailsapp') THEN

   GRANT USAGE ON SCHEMA #{app_schema} TO fphsrailsapp;
   GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA #{app_schema} TO fphsrailsapp;
   GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA #{app_schema} TO fphsrailsapp;
END IF;


END
$body$;
