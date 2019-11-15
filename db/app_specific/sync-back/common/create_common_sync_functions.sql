SET search_path=ml_app;
-------------------------------------------------------

-- Add records to sync_statuses that indicate specific master IDs are in the process of being sync'd
CREATE OR REPLACE FUNCTION lock_transfer_records_with_external_ids_and_events(from_db VARCHAR, to_db VARCHAR, master_ids INTEGER[], external_ids INTEGER[], external_type VARCHAR, events VARCHAR[]) RETURNS INTEGER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT into ml_app.sync_statuses
  ( from_master_id, external_id, external_type, from_db, to_db, event, select_status, created_at, updated_at )
  (
    SELECT unnest(master_ids), unnest(external_ids), external_type, from_db, to_db, unnest(events), 'new', now(), now()
  );

  RETURN 1;

END;
$$;
