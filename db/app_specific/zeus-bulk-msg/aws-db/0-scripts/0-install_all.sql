create schema if not exists bulk_msg AUTHORIZATION fphs;

set search_path=bulk_msg,ml_app;

\i ./bulk/create_zeus_bulk_messages_table.sql
\i ./bulk/create_zeus_bulk_message_recipients_table.sql
\i ./bulk/create_zeus_bulk_message_statuses.sql
\i ./bulk/create_al_bulk_messages.sql
\i ./bulk/create_player_contact_phone_infos.sql
\i ./bulk/dup_check_recipients.sql
\i ./bulk/setup_master.sql

set search_path=bulk_msg,ml_app;
\i ./0-scripts/z_grant_roles.sql
