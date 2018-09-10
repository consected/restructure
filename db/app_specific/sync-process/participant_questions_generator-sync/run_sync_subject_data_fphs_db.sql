CREATE TEMPORARY TABLE temp_{{app_name}}_assignments (
    master_id integer,
    {{app_name}}_id bigint
);

-- variable substitution does not work for the filename
--
\copy temp_{{app_name}}_assignments FROM /tmp/remote_{{app_name}}_ids WITH (format csv, header true);

-- clean up the master_id just to make sure
UPDATE temp_{{app_name}}_assignments SET master_id = NULL;

-- retrieve the master_id for each {{app_name}}_id
UPDATE temp_{{app_name}}_assignments SET master_id = (SELECT master_id FROM {{app_name}}_assignments {{app_name}}_perm WHERE {{app_name}}_perm.{{app_name}}_id = temp_{{app_name}}_assignments.{{app_name}}_id);

\copy (SELECT * FROM temp_{{app_name}}_assignments) TO /tmp/zeus_{{app_name}}_assignments.csv WITH (format csv, header true);
\copy (SELECT id, master_id, first_name, last_name, middle_name, nick_name, birth_date, death_date, user_id, created_at, updated_at, start_year, rank, notes, college, end_year, source FROM player_infos WHERE master_id IN (SELECT master_id FROM temp_{{app_name}}_assignments)) TO /tmp/zeus_{{app_name}}_player_infos.csv WITH (format csv, header true);
\copy (SELECT * FROM player_contacts WHERE master_id IN (SELECT master_id FROM temp_{{app_name}}_assignments)) TO /tmp/zeus_{{app_name}}_player_contacts.csv WITH (format csv, header true);
