create schema ${app_schema} IF NOT EXISTS ${app_schema} AUTHORIZATION fphs;

set search_path=${app_schema},ml_app;

\i ${sql_dir}/${app_dirname}/aws-db/bulk/create_al_bulk_messages.sql
\i ${sql_dir}/${app_dirname}/aws-db/bulk/create_zeus_bulk_message_recipients_table.sql
\i ${sql_dir}/${app_dirname}/aws-db/bulk/create_zeus_bulk_message_statuses.sql
\i ${sql_dir}/${app_dirname}/aws-db/bulk/create_zeus_bulk_messages_table.sql
\i ${sql_dir}/${app_dirname}/aws-db/bulk/dup_check_recipients.sql
\i ${sql_dir}/${app_dirname}/aws-db/bulk/setup_master.sql

set search_path=${app_schema},ml_app;
\i ${sql_dir}/${app_dirname}/aws-db/0-scripts/z_grant_roles.sql
