alter table ml_app.sync_statuses
  add column event varchar,
  add column record_updated_at timestamp without time zone;
