-- REVOKE ALL ON SCHEMA q1 FROM fphs;
GRANT ALL ON SCHEMA q1 TO fphs;

GRANT USAGE ON SCHEMA q1 TO fphsadm;

-- GRANT USAGE ON SCHEMA q1 TO fphsadm;
-- GRANT USAGE ON SCHEMA q1 TO fphsusr;
-- GRANT USAGE ON SCHEMA q1 TO fphsetl;

GRANT SELECT, INSERT, UPDATE, DELETE ON q1.live_merge TO fphsusr;

GRANT SELECT, INSERT, UPDATE, DELETE ON q1.live_merge TO fphsetl;

GRANT SELECT, INSERT, DELETE, TRUNCATE, UPDATE ON q1.live_merge TO fphsadm;

-- GRANT ALL ON ALL SEQUENCES IN SCHEMA q1 TO fphs;
-- GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA q1 TO fphsusr;
-- GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA q1 TO fphsetl;
-- GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA q1 TO fphsadm;

DO $body$
BEGIN
  IF EXISTS (
    SELECT
      *
    FROM
      pg_catalog.pg_roles
    WHERE
      rolname = 'fphsrailsapp') THEN
  GRANT USAGE ON SCHEMA q1 TO fphsrailsapp;
  GRANT SELECT, INSERT, UPDATE, DELETE ON q1.live_merge TO fphsrailsapp;
  GRANT SELECT, INSERT, UPDATE, DELETE ON q1.sc_stage TO fphsrailsapp;
  GRANT SELECT, INSERT, UPDATE, DELETE ON q1.rc_stage TO fphsrailsapp;
  -- GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA q1 TO fphsrailsapp;
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
  GRANT USAGE ON SCHEMA q1 TO fphsrailsapp1;
  GRANT SELECT, INSERT, UPDATE, DELETE ON q1.live_merge TO fphsrailsapp1;
  GRANT SELECT, INSERT, UPDATE, DELETE ON q1.sc_stage TO fphsrailsapp1;
  GRANT SELECT, INSERT, UPDATE, DELETE ON q1.rc_stage TO fphsrailsapp1;
  -- GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA q1 TO fphsrailsapp;
END IF;
END
$body$;

