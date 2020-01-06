SET search_path=ml_app;
-------------------------------------------------------

-- Add records to sync_statuses that indicate specific master IDs are in the process of being sync'd
CREATE OR REPLACE FUNCTION update_ipa_transfer_record_results(new_from_db VARCHAR, new_to_db VARCHAR, for_external_type VARCHAR) RETURNS INTEGER
LANGUAGE plpgsql
AS $$
BEGIN

  UPDATE ml_app.sync_statuses sync
  SET
    select_status = t.status,
    to_master_id = t.to_master_id,
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
    AND (t.event IS NULL and sync.event IS NULL OR sync.event = t.event)
    AND sync.record_updated_at = t.record_updated_at
    AND coalesce(select_status, '') NOT IN ('completed', 'already transferred');

  RETURN 1;

END;
$$;


CREATE OR REPLACE FUNCTION get_etl_user() RETURNS ml_app.users
LANGUAGE plpgsql
AS $$
DECLARE
	etl_user RECORD;
BEGIN
-- We create new records setting user_id for the user with email fphsetl@hms.harvard.edu, rather than the original
-- value from the source database, which probably would not match the user IDs in the remote database.
SELECT *
INTO etl_user
FROM users u
WHERE u.email = 'fphsetl@hms.harvard.edu'
LIMIT 1;

IF NOT FOUND THEN
  RAISE EXCEPTION 'No user with email fphsetl@hms.harvard.edu was found. Can not continue.';
END IF;


RETURN etl_user;

END;
$$;
