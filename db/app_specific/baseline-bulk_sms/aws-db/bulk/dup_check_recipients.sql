set search_path=${app_schema},ml_app;

CREATE UNIQUE INDEX unique_recipient ON zeus_bulk_message_recipients (zeus_bulk_message_id, record_id)
WHERE disabled = false
;
