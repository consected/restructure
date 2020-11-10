set search_path=bulk_msg,ml_app;

CREATE UNIQUE INDEX unique_recipient ON zeus_bulk_message_recipients (zeus_bulk_message_id, record_id)
WHERE disabled = false
;
