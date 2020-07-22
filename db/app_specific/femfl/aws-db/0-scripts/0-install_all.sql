\set ON_ERROR_STOP 1
CREATE SCHEMA IF NOT EXISTS femfl AUTHORIZATION fphs;

SET search_path = femfl, ml_app;

-- # External ID
\i db/app_specific/femfl/aws-db/femfl/create_femfl_assignments.sql
-- # Bio / Demographics
\i db/app_specific/femfl/aws-db/femfl/create_femfl_subjects.sql
SET search_path = femfl, ml_app;

\i db/app_specific/femfl/aws-db/0-scripts/z_grant_roles.sql
