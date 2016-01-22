-- Script created @ 2016-01-22 10:17:40 -0500
set search_path=public; 
 begin;  ;


GRANT SELECT, INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO fphs;
GRANT SELECT,UPDATE,INSERT,DELETE ON ALL TABLES IN SCHEMA public TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO fphs;
SET search_path = public, pg_catalog;
COPY schema_migrations (version) FROM stdin;
\.

 commit; ;
