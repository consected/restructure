set SEARCH_PATH=ml_app,ml_work;

-- Clean item_flags

delete from ml_app.item_flag_history;
delete from ml_app.item_flags;

---Set back addresses ----------------------
-- truncate table ml_app.addresses cascade;
delete from ml_app.address_history;
delete from ml_app.addresses;
alter sequence addresses_id_seq start with 1;
alter sequence address_history_id_seq start with 1;

---Set back player_contacts ----------------------
--truncate table ml_app.player_contacts cascade;
delete from ml_app.player_contact_history;
delete from ml_app.player_contacts;
alter sequence player_contacts_id_seq start with 1;
alter sequence player_contact_history_id_seq start with 1;

---Set back player_infos ----------------------
--truncate table ml_app.player_infos cascade;
delete from ml_app.player_info_history;
delete from ml_app.player_infos;
alter sequence player_infos_id_seq start with 1;
alter sequence player_info_history_id_seq start with 1;



---Set back scantroncs ----------------------
--truncate table ml_app.scantrons cascade;
delete from ml_app.scantron_history;
delete from ml_app.scantrons;
alter sequence scantrons_id_seq start with 1;
alter sequence scantron_history_id_seq start with 1;

---Set back trackers etc -----------------
delete from ml_app.tracker_history;
alter sequence tracker_history_id_seq start with 1;

delete from ml_app.trackers;
alter sequence trackers_id_seq start with 1;


---Set back pro_infos ----------------------
--truncate table ml_app.player_infos cascade;
-- first break the circular reference
update ml_app.masters set pro_info_id = null;
-- now do the delete
delete from ml_app.pro_infos cascade;
alter sequence pro_infos_id_seq start with 1;


---Set back masters ----------------------
--truncate table ml_app.masters cascade;
delete from ml_app.masters;
alter sequence masters_id_seq start with 1;



-- Clean the lookup tables

delete from ml_app.protocol_event_history;
delete from ml_app.sub_process_history;
delete from ml_app.protocol_history;

delete from ml_app.protocol_events;
delete from ml_app.sub_processes;
delete from ml_app.protocols;


delete from ml_app.accuracy_score_history;
delete from ml_app.general_selection_history;
delete from ml_app.college_history;

delete from ml_app.accuracy_scores;
delete from ml_app.general_selections;
delete from ml_app.colleges;

delete from ml_app.item_flag_name_history;
delete from ml_app.item_flag_names;


--------------------------
-- USER SETUP
--------------------------

/* This is only a temp table at the moment. Update the script to make it permanent in the appropriate schema as required 
create temp table user_translation (email varchar, orig_username varchar, user_id integer);
*/

delete from user_translation;

insert into user_translation (email, orig_username) values
('erin_glaser@hms.harvard.edu', 'ITS\eeglaser'),
('alixandra_nozzolillo@hms.harvard.edu', 'ITS\anozzoli'),
('bryan_cortez@hms.harvard.edu', 'ITS\bcortez'),
('ian_shempp@hms.harvard.edu', 'ITS\ishempp'),
('kerrin_tracy@hms.harvard.edu', 'ITS\kmtracy'),
('arobert6', 'ITS\arobert6'),
('kendall_baldwin@hms.harvard.edu', 'ITS\kbaldwin'),
('james_drummey@hms.harvard.edu', 'ITS\jdrummey'),
('caitlin_mccracken@hms.harvard.edu', 'ITS\cmccrack'),
('zubair_butt@hms.harvard.edu', ''),
('phil_ayres@hms.harvard.edu', '');


/* only if the data is not already there... */
insert into ml_app.users (email, created_at, updated_at) 
  select email, now(), now() from user_translation ut1
    where not exists (select email from user_translation ut2 where ut1.email = ut2.email)
;

insert into ml_app.admins (email)  select distinct 'auto-admin' from 
  ml_app.admins a1 where not exists (select email from ml_app.admins a2 where a2.email = 'auto-admin');


update user_translation ut set user_id = (select id from ml_app.users u where u.email = ut.email);
