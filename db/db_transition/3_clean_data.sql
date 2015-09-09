set SEARCH_PATH=ml_app;

update ml_app.player_infos set source = 'NFLPA' where source is null;
update ml_app.player_infos set source = trim(source);

update ml_app.player_contacts set rec_type = 'Phone' where rec_type = 'Paper' AND data ~ '\d{3}-\d{3}-\d{4}';
update ml_app.player_contacts set source = 'Unknown' where source is null or source = 'd';
update ml_app.player_contacts set source = trim(source), rec_type = trim(rec_type);


update ml_app.addresses set country = 'us' where country is null;
update ml_app.addresses set rec_type = 'Unknown' where rec_type is null or rec_type ~* 'cis';
update ml_app.addresses set source = 'Unknown' where source is null;
update ml_app.addresses set rec_type = trim(initcap(rec_type)), source = trim(source);





