set search_path=ml_app;
-------------------------------------------------------
---- Primary Data Repository Database Synchronization functions ----
-------------------------------------------------------
-- See sync_subject_data.sh for more information on usage


-------------------------------------------------------
----> At this point we switch to the Athena FPHS DB
-- Get appropriate data as CSV
----> Switch back to the Zeus DB
-- Generate temporary tables from the exported CSVs
-------------------------------------------------------

-------------------------------------------------------
-- Run through the entries in temporary temp_ipa_assignments table to identify the primary IPA records
-- Call update_primary_ipa_record() for each, pulling matched records from temp_player_infos and temp_player_contacts.
-- Temporary tables are used, since they will already be populated with data from the Zeus server via CSV files
CREATE OR REPLACE FUNCTION update_all_primary_ipa_records() returns INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
	ipa_record RECORD;
BEGIN

	FOR ipa_record IN
	  SELECT * from temp_ipa_assignments
	LOOP

		PERFORM update_primary_ipa_record(
			ipa_record.ipa_id::BIGINT,
			(SELECT (pi::varchar)::player_infos FROM temp_player_infos pi WHERE master_id = ipa_record.master_id LIMIT 1),
			ARRAY(SELECT distinct (pc::varchar)::player_contacts FROM temp_player_contacts pc WHERE master_id = ipa_record.master_id),
			ARRAY(SELECT distinct (a::varchar)::addresses FROM temp_addresses a WHERE master_id = ipa_record.master_id)
		);

		PERFORM updated_ipa_tracker(
			ipa_record.ipa_id::BIGINT,
			ipa_record.event,
			ipa_record.created_at,
			'Activity recorded in Athena: ' || ipa_record.event
		);

	END LOOP;

	return 1;

END;
$$;

-------------------------------------------------------
-- Update records if newer, or create if not existing in
-- player_infos record, multiple player_contacts records, multiple addresses records
-- Pass in the IPA ID to be matched, a single row player info, and arrays of player_contacts and addresses records.
-- Run tests with:
-- select ipa_ops.update_primary_ipa_record(364648868, (select pi from player_infos pi where master_id = 105029 limit 1), ARRAY(select pi from player_contacts pi where master_id = 105029), ARRAY(select pi from addresses pi where master_id = 105029) );
-- Notice that player_contacts and addresses results are converted to an array, using the ARRAY() function, allowing them to be passed to the function.
CREATE OR REPLACE FUNCTION update_primary_ipa_record(match_ipa_id BIGINT, new_player_info_record player_infos, new_player_contact_records player_contacts[], new_address_records addresses[]) returns INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
	found_ipa record;
	etl_user_id INTEGER;
	new_master_id INTEGER;
	player_info record;
	player_contact record;
	address record;
	pc_length INTEGER;
	found_pc record;
	a_length INTEGER;
	found_a record;
	last_id INTEGER;
BEGIN

-- Find the ipa_assignments external identifier record for this master record and
-- validate that it exists
SELECT *
INTO found_ipa
FROM ipa_ops.ipa_assignments ipa
WHERE ipa.ipa_id = match_ipa_id
LIMIT 1;

-- If the IPA external identifier does not exist then the sync should fail.

IF NOT FOUND THEN
	RAISE NOTICE 'Attempting to transfer back an external ID that does not exist: ipa_assigments record found for IPA_ID --> %', (match_ipa_id);
	UPDATE temp_ipa_assignments SET status='invalid sync-back', to_master_id=new_master_id WHERE ipa_id = match_ipa_id;
  RETURN NULL;
END IF;

-- We create new records setting user_id for the user with email fphsetl@hms.harvard.edu, rather than the original
-- value from the source database, which probably would not match the user IDs in the remote database.
SELECT id
INTO etl_user_id
FROM users u
WHERE u.email = 'fphsetl@hms.harvard.edu'
LIMIT 1;

IF NOT FOUND THEN
	RAISE EXCEPTION 'No user with email fphsetl@hms.harvard.edu was found. Can not continue.';
END IF;

UPDATE temp_ipa_assignments SET status='started sync' WHERE ipa_id = match_ipa_id;


RAISE NOTICE 'Updating master record with user_id % and external identifier % into master %', etl_user_id::varchar, match_ipa_id::varchar, new_master_id::varchar;

-- INSERT INTO masters
-- (user_id, created_at, updated_at) VALUES (etl_user_id, now(), now())
-- RETURNING id
-- INTO new_master_id;

-- RAISE NOTICE 'Creating external identifier record %', (match_ipa_id::varchar);

-- INSERT INTO ipa_ops.ipa_assignments
-- (ipa_id, master_id, user_id, created_at, updated_at)
-- VALUES (match_ipa_id, new_master_id, etl_user_id, now(), now());



IF new_player_info_record.master_id IS NULL THEN
	RAISE NOTICE 'No new_player_info_record found for IPA_ID --> %', (match_ipa_id);
	UPDATE temp_ipa_assignments SET status='failed - no player info provided' WHERE ipa_id = match_ipa_id;
	RETURN NULL;
ELSE


	SELECT * FROM player_infos
	INTO player_info
	WHERE
		master_id = new_master_id
		AND new_player_info_record.updated_at IS NOT NULL
		AND updated_at < new_player_info_record.updated_at
	LIMIT 1
	;

	IF player_info IS NULL THEN
		RAISE NOTICE 'No older primary player_infos record found for IPA_ID --> %', (match_ipa_id);

	ELSE

		RAISE NOTICE 'Syncing older player info record %', (new_player_info_record::varchar);

		-- Update the player info record
		UPDATE player_infos
		SET
		(
			first_name,
			last_name,
			middle_name,
			nick_name,
			birth_date,
			death_date,
			user_id,
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
		=
		(
			new_player_info_record.first_name,
			new_player_info_record.last_name,
			new_player_info_record.middle_name,
			new_player_info_record.nick_name,
			new_player_info_record.birth_date,
			new_player_info_record.death_date,
			etl_user_id,
			new_player_info_record.updated_at,
			new_player_info_record.contact_pref,
			new_player_info_record.start_year,
			new_player_info_record.rank,
			new_player_info_record.notes,
			new_player_info_record.contact_id,
			new_player_info_record.college,
			new_player_info_record.end_year,
			new_player_info_record.source
		)
		WHERE player_infos.master_id = new_master_id AND player_infos.id = player_info.id
		RETURNING id
		INTO last_id
		;

	END IF;




END IF;



SELECT array_length(new_player_contact_records, 1)
INTO pc_length;


IF pc_length IS NULL THEN
	RAISE NOTICE 'No new_player_contact_records found for IPA_ID --> %', (match_ipa_id);
ELSE

	RAISE NOTICE 'player contacts length %', (pc_length);

	FOREACH player_contact IN ARRAY new_player_contact_records LOOP

		SELECT * from player_contacts
		INTO found_pc
		WHERE
			master_id = new_master_id AND
			rec_type = player_contact.rec_type AND
			data = player_contact.data
		LIMIT 1;

		IF found_pc.id IS NULL THEN

			RAISE NOTICE 'Inserting player contact record % % for IPA_ID --> %',
				player_contact.rec_type, player_contact.data, match_ipa_id;

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
					new_master_id,
					player_contact.rec_type,
					player_contact.data,
					player_contact.source,
					player_contact.rank,
					etl_user_id,
					player_contact.created_at,
					player_contact.updated_at
			;

		ELSE

			IF found_pc.created_at < player_contact.created_at THEN

				RAISE NOTICE 'Updating player contact record %. It was older than the one found for IPA_ID --> %', found_pc.id, match_ipa_id;

				UPDATE player_contacts
				SET (
					rec_type,
					rank,
					user_id,
					updated_at
				)
				= (
					player_contact.rec_type,
					player_contact.rank,
					etl_user_id,
					player_contact.updated_at
				)
				WHERE
					player_contacts.master_id = new_master_id
					AND player_contacts.id = found_pc.id;


			ELSE
			  RAISE NOTICE 'Skipping player contact record %. It was not older than the one found for IPA_ID --> %', found_pc.id, match_ipa_id;
			END IF;


		END IF;

	END LOOP;

END IF;




SELECT array_length(new_address_records, 1)
INTO a_length;


IF a_length IS NULL THEN
	RAISE NOTICE 'No new_address_records found for IPA_ID --> %', (match_ipa_id);
ELSE

	RAISE NOTICE 'addresses length %', (a_length);

	FOREACH address IN ARRAY new_address_records LOOP

		SELECT * from addresses
		INTO found_a
		WHERE
			master_id = new_master_id AND
			street = address.street AND
			zip = address.zip
		LIMIT 1;

		IF found_a.id IS NULL THEN

		RAISE NOTICE 'Inserting address record % % for IPA_ID --> %',
			address.street, address.zip, match_ipa_id;

		  INSERT INTO addresses
			(
							master_id,
							street,
							street2,
							street3,
							city,
							state,
							zip,
							source,
							rank,
							rec_type,
							user_id,
							created_at,
							updated_at
			)
			SELECT
					new_master_id,
					address.street,
					address.street2,
					address.street3,
					address.city,
					address.state,
					address.zip,
					address.source,
					address.rank,
					address.rec_type,
					etl_user_id,
					address.created_at,
					address.updated_at
			;

		ELSE

		IF found_a.created_at < address.created_at THEN

			RAISE NOTICE 'Updating address record %. It was older than the one found for IPA_ID --> %', found_a.id, match_ipa_id;

			UPDATE addresses
			SET (
				street2,
				street3,
				city,
				state,
				source,
				rank,
				rec_type,
				user_id,
				updated_at
			)
			= (
				address.street2,
				address.street3,
				address.city,
				address.state,
				address.source,
				address.rank,
				address.rec_type,
				etl_user_id,
				address.updated_at
			)
			WHERE
				addresses.master_id = new_master_id
				AND addresses.id = found_a.id;


		ELSE
			RAISE NOTICE 'Skipping address record %. It was not older than the one found for IPA_ID --> %', found_a.id, match_ipa_id;
		END IF;


		END IF;

	END LOOP;

END IF;

RAISE NOTICE 'Setting results for master_id %', (new_master_id);

UPDATE temp_ipa_assignments SET status='completed', to_master_id=new_master_id WHERE ipa_id = match_ipa_id;

return new_master_id;

END;
$$;

----------------------------------------------------------
-- Update the primary tracker with entries specific to the event
CREATE OR REPLACE FUNCTION updated_ipa_tracker(match_ipa_id BIGINT, event VARCHAR, event_date DATETIME, add_notes VARCHAR) returns INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
	found_ipa record;
	protocol_id integer;
	opt_out_id integer;
	complete_id integer;
	withdrew_id integer;
	screened_id integer;
	eligible_id integer;
	ineligible_id integer;
BEGIN


	-- Find the ipa_assignments external identifier record for this master record and
	-- validate that it exists
	SELECT *
	INTO found_ipa
	FROM ipa_ops.ipa_assignments ipa
	WHERE ipa.ipa_id = match_ipa_id
	LIMIT 1;

	-- If the IPA external identifier does not exist then the sync should fail.

	IF NOT FOUND THEN
		RAISE NOTICE 'Attempting to transfer trackers back for an external ID that does not exist: ipa_assigments record found for IPA_ID --> %', (match_ipa_id);
		UPDATE temp_ipa_assignments SET status='invalid tracker sync-back', to_master_id=new_master_id WHERE ipa_id = match_ipa_id;
	  RETURN NULL;
	END IF;

	SELECT id
	FROM protocols
	WHERE
		name = 'In-Person Assessment'
		AND coalesce(disabled, FALSE) = FALSE
	LIMIT 1
	INTO this_protocol_id;


	SELECT id
	FROM sub_processes
	WHERE
		name = 'Opt Out'
		AND coalesce(disabled, FALSE) = FALSE
	LIMIT 1
	INTO opt_out_id;

	SELECT id
	FROM sub_processes
	WHERE
		name = 'Complete'
		AND coalesce(disabled, FALSE) = FALSE
	LIMIT 1
	INTO complete_id;

	SELECT id
	FROM sub_processes
	WHERE
		name = 'Withdrew'
		AND coalesce(disabled, FALSE) = FALSE
	LIMIT 1
	INTO withdrew_id;

	SELECT id
	FROM sub_processes
	WHERE
		name = 'Screened'
		AND coalesce(disabled, FALSE) = FALSE
	LIMIT 1
	INTO screened_id;

	INSERT INTO trackers
	(
		master_id,
		protocol_id,
		sub_process_id,
		protocol_event_id,
		event_date,
		notes
	)
	VALUES
	(
		found_ipa.master_id,
		this_protocol_id,
		CASE event
			WHEN THEN opt_out_id
			WHEN THEN complete_id
			WHEN THEN withdrew_id
			WHEN THEN screened_id
		END,
		CASE event
		  WHEN THEN eligible_id
			WHEN THEN ineligible_id
		END,
		event_date,
		add_notes
	)


END;
$$;
