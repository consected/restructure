REVOKE ALL ON SCHEMA pitt_bhi FROM fphs;

GRANT ALL ON SCHEMA pitt_bhi TO fphs;

GRANT USAGE ON SCHEMA pitt_bhi TO fphsadm;

GRANT USAGE ON SCHEMA pitt_bhi TO fphsusr;

GRANT USAGE ON SCHEMA pitt_bhi TO fphsetl;

GRANT ALL ON ALL TABLES IN SCHEMA pitt_bhi TO fphs;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA pitt_bhi TO fphsusr;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA pitt_bhi TO fphsetl;

GRANT SELECT, INSERT, DELETE, TRUNCATE, UPDATE ON ALL TABLES IN SCHEMA pitt_bhi TO fphsadm;

GRANT ALL ON ALL SEQUENCES IN SCHEMA pitt_bhi TO fphs;

GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA pitt_bhi TO fphsusr;

GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA pitt_bhi TO fphsetl;

GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA pitt_bhi TO fphsadm;

DO $body$
BEGIN
  IF EXISTS (
    SELECT
      *
    FROM
      pg_catalog.pg_roles
    WHERE
      rolname = 'fphsrailsapp') THEN
  GRANT USAGE ON SCHEMA pitt_bhi TO fphsrailsapp;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA pitt_bhi TO fphsrailsapp;

GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA pitt_bhi TO fphsrailsapp;

END IF;

IF EXISTS (
  SELECT
    *
  FROM
    pg_catalog.pg_roles
  WHERE
    rolname = 'fphsrailsapp1') THEN
GRANT USAGE ON SCHEMA pitt_bhi TO fphsrailsapp1;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA pitt_bhi TO fphsrailsapp1;

GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA pitt_bhi TO fphsrailsapp1;

END IF;

END $body$;
