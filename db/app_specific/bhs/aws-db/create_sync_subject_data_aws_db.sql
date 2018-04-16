-------------------------------------------------------
---- Remote AWS Database Synchronization functions ----
-------------------------------------------------------
-- See sync_subject_data.sh for more information on usage


set search_path=ml_app;

-------------------------------------------------------
-- Find the BHS IDs that
-- are not null or the default value of 100 000 000
-- have a master record without a matching player_infos record
CREATE OR REPLACE FUNCTION find_new_remote_bhs_records() RETURNS TABLE (
	master_id integer,
	bhs_id bigint
)
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
		SELECT distinct bhs.master_id, bhs.bhs_id
		FROM masters m
		LEFT JOIN player_infos pi
		ON pi.master_id = m.id
		INNER JOIN bhs_assignments bhs
		ON m.id = bhs.master_id
		INNER JOIN activity_log_bhs_assignments al
		ON m.id = al.master_id AND al.extra_log_type = 'primary'
		WHERE
		  pi.id IS NULL
			AND bhs.bhs_id is not null
			AND bhs.bhs_id <> 100000000
			;
END;
$$;


-------------------------------------------------------
----> At this point we switch to the Zeus FPHS DB
-- Get appropriate data as CSV
----> Switch back to the AWS DB
-- Generate temporary tables from the exported CSVs
-------------------------------------------------------

-------------------------------------------------------
-- Run through the entries in temporary temp_bhs_assignments table to create all the remote BHS records
-- Call create_remote_bhs_record() for each, pulling matched records from temp_player_infos and temp_player_contacts.
-- Temporary tables are used, since they will already be populated with data from the Zeus server via CSV files
CREATE OR REPLACE FUNCTION create_all_remote_bhs_records() returns INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
	bhs_record RECORD;
BEGIN

	FOR bhs_record IN
	  SELECT * from temp_bhs_assignments
	LOOP

		PERFORM create_remote_bhs_record(
			bhs_record.bhs_id,
			(SELECT (pi::varchar)::player_infos FROM temp_player_infos pi WHERE master_id = bhs_record.master_id LIMIT 1),
			ARRAY(SELECT distinct (pc::varchar)::player_contacts FROM temp_player_contacts pc WHERE master_id = bhs_record.master_id)
		);

	END LOOP;

	return 1;

END;
$$;

-------------------------------------------------------
-- Create player_infos record, multiple player_contacts records, and update the activity log record.
-- Pass in the BHS ID to be matched, a single row player info, and an array of player_contacts records.
-- Run tests with:
-- select ml_app.create_remote_bhs_record(364648868, (select pi from player_infos pi where master_id = 105029 limit 1), ARRAY(select pi from player_contacts pi where master_id = 105029) );
-- Notice that player_contacts results are converted to an array, using the ARRAY() function, allowing them to be passed to the function.
CREATE OR REPLACE FUNCTION create_remote_bhs_record(match_bhs_id BIGINT, new_player_info_record player_infos, new_player_contact_records player_contacts[]) returns INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
	found_bhs record;
	player_contact record;
	pc_length INTEGER;
	found_pc record;
	last_id INTEGER;
	phone VARCHAR;
BEGIN

-- Find the bhs_assignments external identifier record for this master record and
-- validate that it exists
SELECT *
INTO found_bhs
FROM bhs_assignments bhs
WHERE bhs.bhs_id = match_bhs_id
LIMIT 1;

-- At this point, if we found the above record, then the master record can be referred to with found_bhs.master_id
-- We also create the new records setting the user_id to match that of the found_bhs record, rather than the original
-- value from the source database, which probably would not match the user IDs in the remote database. The user_id of the
-- found_bhs record is conceptually valid, since it is that user that has effectively kicked off the synchronization process
-- and requested the new player_infos and player_contacts records be created.

IF NOT FOUND THEN
	RAISE EXCEPTION 'No bhs_assigments record found for BHS_ID --> %', (match_bhs_id);
END IF;




IF new_player_info_record.master_id IS NULL THEN
	RAISE NOTICE 'No new_player_info_record found for BHS_ID --> %', (match_bhs_id);
	RETURN NULL;
ELSE

	RAISE NOTICE 'Syncing player info record %', (new_player_info_record::varchar);

	-- Create the player info record
  INSERT INTO player_infos
  (
    master_id,
    first_name,
    last_name,
    middle_name,
    nick_name,
    birth_date,
    death_date,
    user_id,
    created_at,
    updated_at,
    contact_pref,
    start_year,
    rank,
    notes,
    contact_id,
    college,
    end_year,
    source
  )
  SELECT
    found_bhs.master_id,
    new_player_info_record.first_name,
    new_player_info_record.last_name,
    new_player_info_record.middle_name,
    new_player_info_record.nick_name,
    new_player_info_record.birth_date,
    new_player_info_record.death_date,
    found_bhs.user_id,
    new_player_info_record.created_at,
    new_player_info_record.updated_at,
    new_player_info_record.contact_pref,
    new_player_info_record.start_year,
    new_player_info_record.rank,
    new_player_info_record.notes,
    new_player_info_record.contact_id,
    new_player_info_record.college,
    new_player_info_record.end_year,
    new_player_info_record.source

		RETURNING id
	  INTO last_id
	  ;


END IF;



SELECT array_length(new_player_contact_records, 1)
INTO pc_length;


IF pc_length IS NULL THEN
	RAISE NOTICE 'No new_player_contact_records found for BHS_ID --> %', (match_bhs_id);
ELSE

	RAISE NOTICE 'player contacts length %', (pc_length);

	FOREACH player_contact IN ARRAY new_player_contact_records LOOP

		SELECT * from player_contacts
		INTO found_pc
		WHERE
			master_id = found_bhs.master_id AND
			rec_type = player_contact.rec_type AND
			data = player_contact.data
		LIMIT 1;

		IF found_pc.id IS NULL THEN

		  INSERT INTO player_contacts
			(
							master_id,
							rec_type,
							data,
							source,
							rank,
							user_id,
							created_at,
							updated_at
			)
			SELECT
					found_bhs.master_id,
					player_contact.rec_type,
					player_contact.data,
					player_contact.source,
					player_contact.rank,
					found_bhs.user_id,
					player_contact.created_at,
					player_contact.updated_at
			;
		END IF;

	END LOOP;


	SELECT id
	INTO last_id
	FROM activity_log_bhs_assignments
	WHERE
		bhs_assignment_id IS NOT NULL
		AND (select_record_from_player_contact_phones is null OR select_record_from_player_contact_phones = '')
		AND master_id = found_bhs.master_id
		AND extra_log_type = 'primary'
	ORDER BY id ASC
	LIMIT 1;


	-- Get the best phone number
	SELECT data FROM player_contacts
	INTO phone
	WHERE rec_type='phone' AND rank is not null AND master_id = found_bhs.master_id
	ORDER BY rank desc
	LIMIT 1;

	RAISE NOTICE 'best phone number %', (phone);
  RAISE NOTICE 'AL ID %', (last_id);

  -- Now update the activity log record.
	UPDATE activity_log_bhs_assignments
	SET
	  select_record_from_player_contact_phones = phone,
		results_link = ('https://testmybrain.org?demotestid=' || found_bhs.bhs_id::varchar)
	WHERE
		id = last_id;


	-- Now send a notification to the PI
	PERFORM activity_log_bhs_assignment_info_request_notification(last_id);


END IF;

return found_bhs.master_id;

END;
$$;
