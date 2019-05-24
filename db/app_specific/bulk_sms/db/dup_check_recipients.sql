set search_path=ml_app;

CREATE UNIQUE INDEX unique_recipient ON zeus_bulk_message_recipients (zeus_bulk_message_id, item_id);
