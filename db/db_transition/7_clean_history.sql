set SEARCH_PATH=ml_app;

/* Ugly but reliable method for resetting the history tables to the original set of data */

delete from player_info_history;
update player_infos set user_id = (select id from users order id desc limit 1);
delete from player_info_history;
update player_infos set user_id = null;

delete from player_contact_history;
update player_contacts set user_id = (select id from users order by id desc limit 1);
delete from player_contact_history;
update player_contacts set user_id = null;

delete from address_history;
update addresses set user_id = (select id from users order by id desc limit 1);
delete from address_history;
update addresses set user_id = null;
