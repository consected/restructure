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
	primary_count integer;
	event_count integer;
BEGIN

	primary_count := 0;
	event_count := 0;

	FOR ipa_record IN
	  SELECT * from temp_ipa_assignments ORDER BY record_updated_at
	LOOP


		IF ipa_record.event IS NULL THEN

			PERFORM update_primary_ipa_record(
				ipa_record.record_updated_at,
				ipa_record.ipa_id::BIGINT,
				(SELECT (pi::varchar)::player_infos FROM temp_player_infos pi WHERE master_id = ipa_record.master_id LIMIT 1),
				ARRAY(SELECT distinct (pc::varchar)::player_contacts FROM temp_player_contacts pc WHERE master_id = ipa_record.master_id),
				ARRAY(SELECT distinct (a::varchar)::addresses FROM temp_addresses a WHERE master_id = ipa_record.master_id)
			);

			primary_count := primary_count + 1;

		ELSE

			PERFORM updated_ipa_tracker(
				ipa_record.record_updated_at,
				ipa_record.ipa_id::BIGINT,
				ipa_record.event,
				ipa_record.record_updated_at,
				'Activity recorded in Athena: ' || ipa_record.event
			);

			event_count := event_count + 1;

		END IF;

	END LOOP;

	RAISE NOTICE 'Performed updates on primary records (%) and events (%)', primary_count, event_count;

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
CREATE OR REPLACE FUNCTION update_primary_ipa_record(rec_updated_at timestamp without time zone, match_ipa_id BIGINT, new_player_info_record player_infos, new_player_contact_records player_contacts[], new_address_records addresses[]) returns INTEGER
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
	rec_id INTEGER;
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
		RAISE NOTICE 'Attempting to transfer back an external ID that does not exist: ipa_assigments record found for IPA_ID %', (match_ipa_id);
		UPDATE temp_ipa_assignments SET status='invalid sync-back', to_master_id=new_master_id WHERE ipa_id = match_ipa_id AND event IS NULL and record_updated_at = rec_updated_at;
	  RETURN NULL;
	END IF;

	new_master_id := found_ipa.master_id;

	-- We create new records setting user_id for the user with email fphsetl@hms.harvard.edu, rather than the original
	-- value from the source database, which probably would not match the user IDs in the remote database.
	SELECT id FROM get_etl_user()
	INTO etl_user_id
	LIMIT 1;


	UPDATE temp_ipa_assignments SET status='started sync' WHERE ipa_id = match_ipa_id AND event IS NULL and record_updated_at = rec_updated_at;

	-- RAISE NOTICE 'Updating master record with user_id % and external identifier % into master %', etl_user_id::varchar, match_ipa_id::varchar, new_master_id::varchar;

	IF new_player_info_record.master_id IS NULL THEN
		RAISE NOTICE 'No Player Info record found for IPA_ID %', (match_ipa_id);
		UPDATE temp_ipa_assignments SET status='failed - no player info provided' WHERE ipa_id = match_ipa_id AND event IS NULL and record_updated_at = rec_updated_at;
		RETURN NULL;
	ELSE

		-- Since we know the player_infos only contains one entry per master, just find
		-- out if the new record was updated more recently than the original
		SELECT * FROM player_infos
		INTO player_info
		WHERE
			master_id = new_master_id
			AND new_player_info_record.updated_at IS NOT NULL
			AND (
				updated_at IS NULL OR
				updated_at < new_player_info_record.updated_at
			)
		LIMIT 1
		;

		IF player_info IS NULL THEN
			RAISE NOTICE 'No primary Player Info record found for IPA_ID %', (match_ipa_id);

		ELSE

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

			RAISE NOTICE 'Updated player info record id % for IPA_ID %', last_id, match_ipa_id;


		END IF;




	END IF;



	SELECT array_length(new_player_contact_records, 1)
	INTO pc_length;


	IF pc_length IS NULL THEN
		RAISE NOTICE 'No Player Contact records found for IPA_ID %', (match_ipa_id);
	ELSE

		-- RAISE NOTICE 'player contacts length %', (pc_length);

		FOREACH player_contact IN ARRAY new_player_contact_records LOOP

			SELECT * from player_contacts
			INTO found_pc
			WHERE
				master_id = new_master_id AND
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
						new_master_id,
						player_contact.rec_type,
						player_contact.data,
						player_contact.source,
						player_contact.rank,
						etl_user_id,
						player_contact.created_at,
						player_contact.updated_at
				RETURNING id
				INTO rec_id
				;

				RAISE NOTICE 'Inserted Player Contact id % for IPA_ID %', rec_id, match_ipa_id;

			ELSE

				IF found_pc.updated_at IS NULL AND player_contact.updated_at IS NOT NULL OR found_pc.updated_at < player_contact.updated_at THEN


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

					RAISE NOTICE 'Updated Player Contact id % for IPA_ID %', found_pc.id, match_ipa_id;

				-- ELSE
				--   RAISE NOTICE 'Skipping player contact record %. It was not older than the one found for IPA_ID --> %', found_pc.id, match_ipa_id;
				END IF;


			END IF;

		END LOOP;

	END IF;




	SELECT array_length(new_address_records, 1)
	INTO a_length;


	IF a_length IS NULL THEN
		RAISE NOTICE 'No Address records found for IPA_ID %', (match_ipa_id);
	ELSE

		-- RAISE NOTICE 'addresses length %', (a_length);

		FOREACH address IN ARRAY new_address_records LOOP

			SELECT * from addresses
			INTO found_a
			WHERE
				master_id = new_master_id AND
				street = address.street AND
				zip = address.zip
			LIMIT 1;

			IF found_a.id IS NULL THEN

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
				RETURNING id
				INTO rec_id
				;

				RAISE NOTICE 'Inserted Address record id % for IPA_ID %', rec_id, match_ipa_id;

			ELSE

			IF found_a.updated_at IS NULL AND address.updated_at IS NOT NULL OR found_a.updated_at < address.updated_at THEN


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

				RAISE NOTICE 'Updated Address record % id for IPA_ID %', found_a.id, match_ipa_id;

			-- ELSE
			-- 	RAISE NOTICE 'Skipping address record %. It was not older than the one found for IPA_ID --> %', found_a.id, match_ipa_id;
			END IF;


			END IF;

		END LOOP;

	END IF;

	-- RAISE NOTICE 'Setting completed status for master_id % with ipa_id % updated at %', new_master_id, match_ipa_id::varchar, rec_updated_at::varchar;

	UPDATE temp_ipa_assignments SET status='completed', to_master_id=new_master_id WHERE ipa_id = match_ipa_id AND event IS NULL and record_updated_at = rec_updated_at;

	return new_master_id;

END;
$$;

----------------------------------------------------------
-- Update the primary tracker with entries specific to the event
CREATE OR REPLACE FUNCTION updated_ipa_tracker(rec_updated_at timestamp without time zone, match_ipa_id BIGINT, for_event VARCHAR, event_date timestamp without time zone, add_notes VARCHAR) returns INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
	rec_id integer;
  etl_user_id integer;
	found_ipa record;
	new_master_id integer;
	this_protocol_id integer;
	opt_out_id integer;
	complete_id integer;
	withdrew_id integer;
	screened_id integer;
	eligible_id integer;
	ineligible_id integer;
	scheduled_id integer;
	l2fu_id integer;

BEGIN

	-- We create new records setting user_id for the user with email fphsetl@hms.harvard.edu, rather than the original
	-- value from the source database, which probably would not match the user IDs in the remote database.
	SELECT id FROM get_etl_user()
	INTO etl_user_id
	LIMIT 1;


	-- Find the ipa_assignments external identifier record for this master record and
	-- validate that it exists
	SELECT *
	INTO found_ipa
	FROM ipa_ops.ipa_assignments ipa
	WHERE ipa.ipa_id = match_ipa_id
	LIMIT 1;

	new_master_id := found_ipa.master_id;

	-- If the IPA external identifier does not exist then the sync should fail.

	IF NOT FOUND THEN
		RAISE NOTICE 'Attempting to transfer trackers back for an external ID that does not exist: ipa_assigments record found for IPA_ID %', (match_ipa_id);
		UPDATE temp_ipa_assignments SET status='invalid tracker sync-back', to_master_id=new_master_id WHERE ipa_id = match_ipa_id AND event = for_event and record_updated_at = rec_updated_at;
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
		protocol_id = this_protocol_id
		AND name = 'Opt Out'
		AND coalesce(disabled, FALSE) = FALSE
	LIMIT 1
	INTO opt_out_id;

	SELECT id
	FROM sub_processes
	WHERE
		protocol_id = this_protocol_id
		AND name = 'Complete'
		AND coalesce(disabled, FALSE) = FALSE
	LIMIT 1
	INTO complete_id;

	SELECT id
	FROM sub_processes
	WHERE
		protocol_id = this_protocol_id
		AND name = 'Withdrew'
		AND coalesce(disabled, FALSE) = FALSE
	LIMIT 1
	INTO withdrew_id;

	SELECT id
	FROM sub_processes
	WHERE
		protocol_id = this_protocol_id
		AND name = 'Screened'
		AND coalesce(disabled, FALSE) = FALSE
	LIMIT 1
	INTO screened_id;

	SELECT id
	FROM sub_processes
	WHERE
		protocol_id = this_protocol_id
		AND name = 'Eligible'
		AND coalesce(disabled, FALSE) = FALSE
	LIMIT 1
	INTO eligible_id;

	SELECT id
	FROM sub_processes
	WHERE
		protocol_id = this_protocol_id
		AND name = 'Ineligible'
		AND coalesce(disabled, FALSE) = FALSE
	LIMIT 1
	INTO ineligible_id;

	SELECT id
	FROM sub_processes
	WHERE
		protocol_id = this_protocol_id
		AND name = 'Scheduled'
		AND coalesce(disabled, FALSE) = FALSE
	LIMIT 1
	INTO scheduled_id;

	SELECT id
	FROM sub_processes
	WHERE
		protocol_id = this_protocol_id
		AND name = 'Lost to Follow Up, Not Enrolled'
		AND coalesce(disabled, FALSE) = FALSE
	LIMIT 1
	INTO l2fu_id;

	INSERT INTO trackers
	(
		master_id,
		protocol_id,
		sub_process_id,
		protocol_event_id,
		event_date,
		notes,
		created_at,
		updated_at,
		user_id
	)
	VALUES
	(
		found_ipa.master_id,
		this_protocol_id,
		CASE for_event
			WHEN 'not interest during phone screening' THEN opt_out_id
			WHEN 'not interest during screening follow-up' THEN opt_out_id
			WHEN 'completed' THEN complete_id
			WHEN 'withdrawn' THEN withdrew_id
			WHEN 'scheduled' THEN scheduled_id
			WHEN 'not eligible' THEN ineligible_id
			WHEN 'eligible' THEN eligible_id
			WHEN 'eligible with study partner' THEN eligible_id
			WHEN 'screened' THEN screened_id
			WHEN 'lost to follow up' THEN l2fu_id
		END,
		NULL,
		event_date,
		add_notes,
		now(),
		now(),
		etl_user_id

	)
	RETURNING id
	INTO rec_id
	;

	UPDATE temp_ipa_assignments SET status='completed', to_master_id=new_master_id WHERE ipa_id = match_ipa_id AND event = for_event and record_updated_at = rec_updated_at;

	RAISE NOTICE 'Inserted Event "%" for IPA_ID %', for_event, match_ipa_id;

	return new_master_id;

END;
$$;
