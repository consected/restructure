set search_path=ml_app, ipa_ops;

CREATE UNIQUE INDEX unique_recipient ON zeus_bulk_message_recipients (zeus_bulk_message_id, record_id)
WHERE disabled = false
;
