set SEARCH_PATH=ml_app;

update ml_app.player_infos set source = trim(source);

update ml_app.player_infos set source = 'Not Set' where source is null;


update ml_app.player_contacts set rec_type = 'Phone' where rec_type = 'Paper' AND data ~ '\d{3}-\d{3}-\d{4}';

update ml_app.player_contacts set source = trim(source), rec_type = trim(rec_type);
update ml_app.player_contacts set source = 'Not Set' where source is null;



update ml_app.addresses set country = 'us' where country is null;
update ml_app.addresses set rec_type = trim(initcap(rec_type)), source = trim(source);
update ml_app.addresses set rec_type = 'Home' where rec_type ~* 'hom';

update ml_app.addresses set source = 'Not Set' where source is null;
update ml_app.addresses set rec_type = 'Not Set' where rec_type is null;



update ml_app.addresses set street2 = null where street2 ~* 'null';
update ml_app.addresses set zip = '0'|| trim(zip)  where trim(zip) ~ '^\d{4,4}$';

