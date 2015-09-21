set SEARCH_PATH=ml_app;
/* The names for the accuracy scores are temporary, during setup. They match seed data in the code, and will prevent additional unnecessary accuracy score 
   records being created during initial database seeding.
   All names can be changed in the app through admin functionality after initial configuration.
*/

delete from ml_app.accuracy_scores;
delete from ml_app.general_selections;
delete from ml_app.colleges;


insert into ml_app.accuracy_scores 
(name, value, created_at, updated_at) values
('Current player', 333, now(), now()),
('Good match', 12, now(), now()),
('Reasonable match', 8, now(), now()),
('Minimal match', 2, now(), now()),
('OK match', 10, now(), now()),
('Deceased', 777, now(), now()),
('Bad match - must keep', 888, now(), now()),
('Minimal match 4', 4, now(), now()),
('Bad match - requires follow up', 881, now(), now()),
('Bad match & duplicate', 999, now(), now()),
('Better match', 9, now(), now()),
('Poor match', 0, now(), now()),
('Medium match', 7, now(), now()),
('Ineligible', 555, now(), now());


insert into ml_app.general_selections 
(item_type, name, value, created_at, updated_at) values
('addresses_rank', 'primary', '10', now(), now()),
('addresses_rank', 'secondary', '5', now(), now()),
('addresses_rank', 'do not use', '0', now(), now()),
('addresses_rank', 'bad contact', '-1', now(), now()),
('player_contacts_rank', 'primary', '10', now(), now()),
('player_contacts_rank', 'secondary', '5', now(), now()),
('player_contacts_rank', 'do not use', '0', now(), now()),
('player_contacts_rank', 'bad contact', '-1', now(), now());


insert into ml_app.general_selections 
(item_type, name, value, created_at, updated_at) 
  select distinct 'player_infos_source', source, lower(source), now(), now() from player_infos;

insert into ml_app.general_selections 
(item_type, name, value, created_at, updated_at) 
  select distinct 'player_contacts_source', source, lower(source), now(), now() from player_contacts;

insert into ml_app.general_selections 
(item_type, name, value, created_at, updated_at) 
  select distinct 'player_contacts_type', rec_type, lower(rec_type), now(), now() from player_contacts;

insert into ml_app.general_selections 
(item_type, name, value, created_at, updated_at) 
  select distinct 'addresses_source', source, lower(source), now(), now() from addresses;

insert into ml_app.general_selections 
(item_type, name, value, created_at, updated_at) 
  select distinct 'addresses_type', rec_type, lower(rec_type), now(), now() from addresses;


update ml_app.player_infos set source = lower(source), college = lower(college), first_name = lower(first_name), last_name = lower(last_name), middle_name = lower(middle_name), nick_name = lower(nick_name);
update ml_app.player_contacts set source = lower(source), rec_type = lower(rec_type), data = lower(data);
update ml_app.addresses set street = lower(street), street2 = lower(street2), street3 = lower(street3), city=lower(city), state=lower(state), country=lower(country), rec_type=lower(rec_type), source=lower(source);


insert into colleges (name) (select distinct college from pro_infos where college is not null order by college);

insert into colleges (name) (select distinct player_infos.college from player_infos where player_infos.college is not null and not exists (select distinct pro_infos.college from pro_infos where player_infos.college = pro_infos.college));
