\set ON_ERROR_STOP 1

create schema IF NOT EXISTS data_requests AUTHORIZATION fphs;

set  search_path = data_requests, ml_app;

-- # External ID
\i db/app_specific/data_requests/aws-db/data_request/create_data_request_assignments.sql

-- # Activity Log
\i db/app_specific/data_requests/aws-db/data_request/create_activity_log_data_request_assignments.sql


set  search_path = data_requests, ml_app;
\i db/app_specific/data_requests/aws-db/0-scripts/z_grant_roles.sql