CREATE TEMPORARY TABLE temp_bhs_assignments (
    master_id integer,
    bhs_id bigint
);

-- variable substitution does not work for the filename
--
\copy temp_bhs_assignments FROM /tmp/remote_bhs_ids WITH (format csv, header true);

-- clean up the master_id just to make sure
UPDATE temp_bhs_assignments SET master_id = NULL;

-- retrieve the master_id for each bhs_id
UPDATE temp_bhs_assignments SET master_id = (SELECT master_id FROM bhs_assignments bhs_perm WHERE bhs_perm.bhs_id = temp_bhs_assignments.bhs_id);

\copy (SELECT * FROM temp_bhs_assignments) TO /tmp/zeus_bhs_assignments.csv WITH (format csv, header true);
\copy (SELECT id, master_id, first_name, last_name, middle_name, nick_name, birth_date, death_date, user_id, created_at, updated_at, start_year, rank, notes, college, end_year, source FROM player_infos WHERE master_id IN (SELECT master_id FROM temp_bhs_assignments)) TO /tmp/zeus_bhs_player_infos.csv WITH (format csv, header true);
\copy (SELECT * FROM player_contacts WHERE master_id IN (SELECT master_id FROM temp_bhs_assignments)) TO /tmp/zeus_bhs_player_contacts.csv WITH (format csv, header true);
