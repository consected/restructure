CREATE TEMPORARY TABLE temp_ipa_assignments (
    master_id integer,
    ipa_id bigint
);

-- variable substitution does not work for the filename
--
\copy temp_ipa_assignments FROM /tmp/remote_ipa_ids WITH (format csv, header true);

-- clean up the master_id just to make sure
UPDATE temp_ipa_assignments SET master_id = NULL;

-- retrieve the master_id for each ipa_id
UPDATE temp_ipa_assignments SET master_id = (SELECT master_id FROM ipa_assignments ipa_perm WHERE ipa_perm.ipa_id = temp_ipa_assignments.ipa_id);

\copy (SELECT * FROM temp_ipa_assignments) TO /tmp/zeus_ipa_assignments.csv WITH (format csv, header true);
\copy (SELECT id, master_id, first_name, last_name, middle_name, nick_name, birth_date, death_date, user_id, created_at, updated_at, start_year, rank, notes, college, end_year, source FROM player_infos WHERE master_id IN (SELECT master_id FROM temp_ipa_assignments)) TO /tmp/zeus_ipa_player_infos.csv WITH (format csv, header true);
\copy (SELECT * FROM player_contacts WHERE master_id IN (SELECT master_id FROM temp_ipa_assignments)) TO /tmp/zeus_ipa_player_contacts.csv WITH (format csv, header true);
\copy (SELECT * FROM addresses WHERE master_id IN (SELECT master_id FROM temp_ipa_assignments)) TO /tmp/zeus_ipa_addresses.csv WITH (format csv, header true);
