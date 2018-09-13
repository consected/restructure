SET SEARCH_PATH={{app_schema}},ml_app;

-- REVOKE ALL ON SCHEMA ml_app FROM fphs;
-- GRANT ALL ON SCHEMA ml_app TO fphs;
-- GRANT USAGE ON SCHEMA ml_app TO fphsadm;
-- GRANT USAGE ON SCHEMA ml_app TO fphsusr;
-- GRANT USAGE ON SCHEMA ml_app TO fphsetl;
--
--
-- GRANT ALL ON ALL TABLES IN SCHEMA ml_app TO fphs;
-- GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphsusr;
-- GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphsetl;
-- GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON ALL TABLES IN SCHEMA ml_app TO fphsadm;
--
-- GRANT ALL ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
-- GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphsusr;
-- GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphsetl;
-- GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphsadm;
--
-- GRANT USAGE ON SCHEMA ml_app TO fphsrailsapp;
-- GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphsrailsapp;
-- GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphsrailsapp;

-- Handle new schema

REVOKE ALL ON SCHEMA {{app_schema}} FROM fphs;
GRANT ALL ON SCHEMA {{app_schema}} TO fphs;
GRANT USAGE ON SCHEMA {{app_schema}} TO fphsadm;
GRANT USAGE ON SCHEMA {{app_schema}} TO fphsusr;
GRANT USAGE ON SCHEMA {{app_schema}} TO fphsetl;


GRANT ALL ON ALL TABLES IN SCHEMA {{app_schema}} TO fphs;
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA {{app_schema}} TO fphsusr;
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA {{app_schema}} TO fphsetl;
GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON ALL TABLES IN SCHEMA {{app_schema}} TO fphsadm;

GRANT ALL ON ALL SEQUENCES IN SCHEMA {{app_schema}} TO fphs;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA {{app_schema}} TO fphsusr;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA {{app_schema}} TO fphsetl;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA {{app_schema}} TO fphsadm;

GRANT USAGE ON SCHEMA {{app_schema}} TO fphsrailsapp;
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA {{app_schema}} TO fphsrailsapp;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA {{app_schema}} TO fphsrailsapp;
