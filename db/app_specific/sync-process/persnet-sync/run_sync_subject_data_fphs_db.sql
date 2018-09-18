CREATE TEMPORARY TABLE temp_persnet_assignments (
    master_id integer,
    persnet_id bigint,
    container_id integer
);

-- variable substitution does not work for the filename
--
\copy temp_persnet_assignments FROM $PERSNET_IDS_FILE WITH (format csv, header true);

-- clean up the master_id just to make sure
UPDATE temp_persnet_assignments SET master_id = NULL;

-- retrieve the master_id for each persnet_id
UPDATE temp_persnet_assignments SET master_id = (SELECT master_id FROM persnet_assignments persnet_perm WHERE persnet_perm.persnet_id = temp_persnet_assignments.persnet_id);

\copy (SELECT * FROM temp_persnet_assignments) TO $PERSNET_ASSIGNMENTS_FILE WITH (format csv, header true);
\copy (SELECT id, master_id, first_name, last_name, middle_name, nick_name, birth_date, death_date, user_id, created_at, updated_at, start_year, rank, notes, college, end_year, source FROM player_infos WHERE master_id IN (SELECT master_id FROM temp_persnet_assignments)) TO $PERSNET_PLAYER_INFOS_FILE WITH (format csv, header true);
\copy (SELECT * FROM player_contacts WHERE master_id IN (SELECT master_id FROM temp_persnet_assignments)) TO $PERSNET_PLAYER_CONTACTS_FILE WITH (format csv, header true);
