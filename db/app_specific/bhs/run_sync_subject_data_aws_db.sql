-- SQL run by sync_subject_data.sh
-- Running this SQL script independently does not make sense
set search_path=ml_app;

CREATE TEMPORARY TABLE temp_bhs_assignments (
    master_id integer,
    bhs_id bigint
);

CREATE TEMPORARY TABLE temp_player_infos AS ( SELECT * FROM player_infos WHERE ID IS NULL);
CREATE TEMPORARY TABLE temp_player_contacts AS ( SELECT * FROM player_contacts WHERE ID IS NULL);

\copy temp_bhs_assignments from /tmp/zeus_bhs_assignments.csv with (header true, format csv)
\copy temp_player_infos from /tmp/zeus_bhs_player_infos.csv with (header true, format csv)
\copy temp_player_contacts from /tmp/zeus_bhs_player_contacts.csv with (header true, format csv)

SELECT create_all_remote_bhs_records();
