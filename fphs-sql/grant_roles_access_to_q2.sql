-- REVOKE ALL ON SCHEMA q2 FROM fphs;
GRANT ALL ON SCHEMA q2 TO fphs;

GRANT USAGE ON SCHEMA q2 TO fphsadm;

-- GRANT USAGE ON SCHEMA q2 TO fphsadm;
-- GRANT USAGE ON SCHEMA q2 TO fphsusr;
-- GRANT USAGE ON SCHEMA q2 TO fphsetl;

GRANT SELECT, INSERT, UPDATE, DELETE ON q2.q2_data TO fphsusr;

GRANT SELECT, INSERT, UPDATE, DELETE ON q2.q2_data TO fphsetl;

GRANT SELECT, INSERT, DELETE, TRUNCATE, UPDATE ON q2.q2_data TO fphsadm;

-- GRANT ALL ON ALL SEQUENCES IN SCHEMA q2 TO fphs;
-- GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA q2 TO fphsusr;
-- GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA q2 TO fphsetl;
-- GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA q2 TO fphsadm;

DO $body$
BEGIN
  IF EXISTS (
    SELECT
      *
    FROM
      pg_catalog.pg_roles
    WHERE
      rolname = 'fphsrailsapp') THEN
  GRANT USAGE ON SCHEMA q2 TO fphsrailsapp;
  GRANT SELECT, INSERT, UPDATE, DELETE ON q2.q2_data TO fphsrailsapp;
END IF;
END
$body$;

DO $body$
BEGIN
  IF EXISTS (
    SELECT
      *
    FROM
      pg_catalog.pg_roles
    WHERE
      rolname = 'fphsrailsapp1') THEN
  GRANT USAGE ON SCHEMA q2 TO fphsrailsapp1;
  GRANT SELECT, INSERT, UPDATE, DELETE ON q2.q2_data TO fphsrailsapp1;
END IF;
END
$body$;

