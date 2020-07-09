\set ON_ERROR_STOP 1

create schema IF NOT EXISTS data_requests AUTHORIZATION fphs;

set  search_path = data_requests, ml_app;

-- # External ID
\i db/app_specific/data_requests/aws-db/data_requests/create_data_request_assignments.sql

-- # Activity Log
\i db/app_specific/data_requests/aws-db/data_requests/create_activity_log_data_request_assignments.sql

-- # Messages
\i db/app_specific/data_requests/aws-db/data_requests/create_data_request_messages.sql           

-- # Data Requests form
\i db/app_specific/data_requests/aws-db/data_requests/create_data_requests.sql

-- # Initial reviews form
\i db/app_specific/data_requests/aws-db/data_requests/create_data_request_initial_reviews.sql  

-- # Requests
\i db/app_specific/data_requests/aws-db/data_requests/create_data_request_attribs.sql          
\i db/app_specific/data_requests/aws-db/data_requests/create_data_requests_selected_attribs.sql


set  search_path = data_requests, ml_app;
\i db/app_specific/data_requests/aws-db/0-scripts/z_grant_roles.sql