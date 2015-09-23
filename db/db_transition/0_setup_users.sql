/* This is only a temp table at the moment. Update the script to make it permanent in the appropriate schema as require */

set SEARCH_PATH=ml_app;

create temp table user_translation (email varchar, orig_username varchar, user_id integer);

insert into user_translation (email, orig_username) values
('erin_glaser@hms.harvard.edu', 'ITS\eeglaser'),
('alixandra_nozzolillo@hms.harvard.edu', 'ITS\anozzoli'),
('bryan_cortez@hms.harvard.edu', 'ITS\bcortez'),
('ian_shempp@hms.harvard.edu', 'ITS\ishempp'),
('kerrin_tracy@hms.harvard.edu', 'ITS\ktracy'),
('arobert6', 'ITS\arobert6'),
('kendall_baldwin@hms.harvard.edu', 'ITS\kbaldwin'),
('james_drummey@hms.harvard.edu', 'ITS\jdrummey'),
('caitlin_mccracken@hms.harvard.edu', 'ITS\cmccrack'),
('zubair_butt@hms.harvard.edu', ''),
('phil_ayres@hms.harvard.edu', '');


/* only if the data is not already there... */
insert into ml_app.users (email, created_at, updated_at) 
  select email, now(), now() from user_translation;


update user_translation ut set user_id = (select id from ml_app.users u where u.email = ut.email);
