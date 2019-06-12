create schema bulk_msg IF NOT EXISTS bulk_msg AUTHORIZATION fphs;

set search_path=bulk_msg,ml_app;

\i db/app_specific/persnet-bulk-msg/aws-db/bulk/create_al_bulk_messages.sql
\i db/app_specific/persnet-bulk-msg/aws-db/bulk/create_zeus_bulk_message_recipients_table.sql
\i db/app_specific/persnet-bulk-msg/aws-db/bulk/create_zeus_bulk_messages_table.sql
\i db/app_specific/persnet-bulk-msg/aws-db/bulk/dup_check_recipients.sql
\i db/app_specific/persnet-bulk-msg/aws-db/bulk/setup_master.sql

set search_path=bulk_msg,ml_app;
\i db/app_specific/persnet-bulk-msg/aws-db/0-scripts/z_grant_roles.sql
