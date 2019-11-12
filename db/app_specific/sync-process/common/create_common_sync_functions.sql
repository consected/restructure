SET search_path=ml_app;

-- Add records to sync_statuses that indicate specific master IDs with external IDs are in the process of being sync'd
CREATE FUNCTION lock_transfer_records_with_external_ids(from_db VARCHAR, to_db VARCHAR, master_ids INTEGER[], external_ids INTEGER[], external_type VARCHAR) RETURNS INTEGER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT into sync_statuses
  ( from_master_id, external_id, external_type, from_db, to_db, select_status, created_at, updated_at )
  (
    SELECT unnest(master_ids), unnest(external_ids), external_type, from_db, to_db, 'new', now(), now()
  );

  RETURN 1;

END;
$$;
