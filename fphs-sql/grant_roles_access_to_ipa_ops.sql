REVOKE ALL ON SCHEMA ipa_ops FROM fphs;

GRANT ALL ON SCHEMA ipa_ops TO fphs;

GRANT USAGE ON SCHEMA ipa_ops TO fphsadm;

GRANT USAGE ON SCHEMA ipa_ops TO fphsusr;

GRANT USAGE ON SCHEMA ipa_ops TO fphsetl;

GRANT ALL ON ALL TABLES IN SCHEMA ipa_ops TO fphs;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ipa_ops TO fphsusr;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ipa_ops TO fphsetl;

GRANT SELECT, INSERT, DELETE, TRUNCATE, UPDATE ON ALL TABLES IN SCHEMA ipa_ops TO fphsadm;

GRANT ALL ON ALL SEQUENCES IN SCHEMA ipa_ops TO fphs;

GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA ipa_ops TO fphsusr;

GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA ipa_ops TO fphsetl;

GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA ipa_ops TO fphsadm;

DO $body$
BEGIN
  IF EXISTS (
    SELECT
      *
    FROM
      pg_catalog.pg_roles
    WHERE
      rolname = 'fphsrailsapp') THEN
  GRANT USAGE ON SCHEMA ipa_ops TO fphsrailsapp;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ipa_ops TO fphsrailsapp;

GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA ipa_ops TO fphsrailsapp;

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
  GRANT USAGE ON SCHEMA ipa_ops TO fphsrailsapp1;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ipa_ops TO fphsrailsapp1;

GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA ipa_ops TO fphsrailsapp1;

END IF;

END $body$;
