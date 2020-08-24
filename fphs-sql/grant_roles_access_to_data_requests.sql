REVOKE ALL ON SCHEMA data_requests FROM fphs;

GRANT ALL ON SCHEMA data_requests TO fphs;

GRANT USAGE ON SCHEMA data_requests TO fphsadm;

GRANT USAGE ON SCHEMA data_requests TO fphsusr;

GRANT USAGE ON SCHEMA data_requests TO fphsetl;

GRANT ALL ON ALL TABLES IN SCHEMA data_requests TO fphs;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA data_requests TO fphsusr;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA data_requests TO fphsetl;

GRANT SELECT, INSERT, DELETE, TRUNCATE, UPDATE ON ALL TABLES IN SCHEMA data_requests TO fphsadm;

GRANT ALL ON ALL SEQUENCES IN SCHEMA data_requests TO fphs;

GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA data_requests TO fphsusr;

GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA data_requests TO fphsetl;

GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA data_requests TO fphsadm;

DO $body$
BEGIN
  IF EXISTS (
    SELECT
      *
    FROM
      pg_catalog.pg_roles
    WHERE
      rolname = 'fphsrailsapp') THEN
  GRANT USAGE ON SCHEMA data_requests TO fphsrailsapp;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA data_requests TO fphsrailsapp;

GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA data_requests TO fphsrailsapp;

END IF;

END $body$; DO $body$
BEGIN
  IF EXISTS (
    SELECT
      *
    FROM
      pg_catalog.pg_roles
    WHERE
      rolname = 'fphsrailsapp1') THEN
  GRANT USAGE ON SCHEMA data_requests TO fphsrailsapp1;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA data_requests TO fphsrailsapp1;

GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA data_requests TO fphsrailsapp1;

END IF;

END $body$;
