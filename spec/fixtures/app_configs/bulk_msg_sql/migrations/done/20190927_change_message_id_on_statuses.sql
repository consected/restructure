set search_path=bulk_msg,ml_app;

alter TABLE zeus_bulk_message_statuses
alter column message_id type varchar;

alter TABLE zeus_bulk_message_status_history
alter column message_id type varchar;
