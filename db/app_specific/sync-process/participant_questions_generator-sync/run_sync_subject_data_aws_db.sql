-- SQL run by sync_subject_data.sh
-- Running this SQL script independently does not make sense
set search_path={{app_schema}},ml_app;

CREATE TEMPORARY TABLE temp_{{app_name}}_assignments (
    master_id integer,
    {{app_name}}_id bigint,
    status varchar,
    to_master_id integer
);

CREATE TEMPORARY TABLE temp_player_infos AS ( SELECT * FROM player_infos WHERE ID IS NULL);
CREATE TEMPORARY TABLE temp_player_contacts AS ( SELECT * FROM player_contacts WHERE ID IS NULL);

\copy temp_{{app_name}}_assignments (master_id, {{app_name}}_id) from ${{app_name_uc}}_ASSIGNMENTS_FILE with (header true, format csv)
\copy temp_player_infos (id, master_id, first_name, last_name, middle_name, nick_name, birth_date, death_date, user_id, created_at, updated_at, start_year, rank, notes, college, end_year, source) from ${{app_name_uc}}_PLAYER_INFOS_FILE with (header true, format csv)
\copy temp_player_contacts from ${{app_name_uc}}_PLAYER_CONTACTS_FILE with (header true, format csv)

SELECT create_all_remote_{{app_name}}_records();

\copy (SELECT * FROM temp_{{app_name}}_assignments) TO ${{app_name_uc}}_ASSIGNMENTS_RESULTS_FILE WITH (format csv, header true);
