DBNAME=fphs_demo
DBOWNER=`whoami`
SCHEMA_NAME=ml_app

cd $(dirname $0)

sudo -u postgres psql -c "create database $DBNAME with owner $DBOWNER;"
sudo -u postgres psql -d $DBNAME -c "create schema $SCHEMA_NAME;"
sudo -u postgres psql -d $DBNAME < create_roles.sql
sudo -u postgres psql -d $DBNAME < grant_roles_access_to_ml_app.sql
sudo -u postgres psql -d $DBNAME -c "alter user fphsetl login; alter user fphsetl  password 'fphs';"
sudo -u postgres psql -d $DBNAME -c "GRANT ALL ON SCHEMA $SCHEMA_NAME TO $DBOWNER;"
sudo -u postgres psql -d $DBNAME -c "GRANT ALL ON ALL TABLES IN SCHEMA $SCHEMA_NAME TO $DBOWNER;"
sudo -u postgres psql -d $DBNAME -c "GRANT ALL ON ALL SEQUENCES IN SCHEMA $SCHEMA_NAME TO $DBOWNER;"
psql -d $DBNAME < ../db/v6-dump.sql

bundle exec rake db:migrate