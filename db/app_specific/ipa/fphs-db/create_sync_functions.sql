SET search_path=ml_app;
-------------------------------------------------------
-- Find the IPA IDs that
-- are not null or the default value of 100 000 000
-- have a master record without a matching player_infos record
CREATE OR REPLACE FUNCTION find_new_local_ipa_records(sel_sub_process_id INTEGER) RETURNS TABLE (
	master_id integer,
  ipa_id integer
)
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
		SELECT distinct m.id, ipa.ipa_id
		FROM masters m
		INNER JOIN ipa_assignments ipa
			ON m.id = ipa.master_id
		INNER JOIN tracker_history th
    	ON m.id = th.master_id
		LEFT JOIN sync_statuses s
			ON from_db = 'fphs-db'
	    AND to_db = 'athena-db'
			AND m.id = s.from_master_id
		WHERE
			ipa.ipa_id is not null
    	AND th.sub_process_id = sel_sub_process_id
			AND s.select_status IS NULL
		;
END;
$$;

CREATE OR REPLACE FUNCTION lock_transfer_records(from_db VARCHAR, to_db VARCHAR, master_ids INTEGER[]) RETURNS INTEGER
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT into sync_statuses
	( from_master_id, from_db, to_db, select_status )
	(
		SELECT unnest(master_ids), from_db, to_db, 'new'
	);

	RETURN 1;

END;
$$;
