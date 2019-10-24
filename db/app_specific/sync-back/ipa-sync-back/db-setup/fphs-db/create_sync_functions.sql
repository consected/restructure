SET search_path=ml_app;
-------------------------------------------------------

-- Add records to sync_statuses that indicate specific master IDs are in the process of being sync'd
CREATE OR REPLACE FUNCTION update_transfer_record_results(new_from_db VARCHAR, new_to_db VARCHAR, for_external_type VARCHAR) RETURNS INTEGER
LANGUAGE plpgsql
AS $$
BEGIN

  UPDATE ml_app.sync_statuses
  SET
    select_status = t.status,
    to_master_id = t.to_master_id,
    event = t.event,
    updated_at = now()
  FROM (
    SELECT * FROM temp_ipa_assignments_results
  ) AS t
  WHERE
    from_master_id = t.master_id
    AND from_db = new_from_db
    AND to_db = new_to_db
    AND external_id = t.ipa_id::varchar
    AND external_type = for_external_type
    AND coalesce(select_status, '') NOT IN ('completed', 'already transferred');

END;
$$;
