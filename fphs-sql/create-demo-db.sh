DBNAME=fphs_demo
DBOWNER=`whoami`

cd $(dirname $0)

sudo -u postgres psql -c "create database $DBNAME with owner $DBOWNER;"
sudo -u postgres psql -d $DBNAME < create_roles.sql
sudo -u postgres psql -d $DBNAME < grant_roles_access_to_ml_app.sql
sudo -u postgres psql -d $DBNAME -c "alter user fphsetl login; alter user fphsetl  password 'fphs';"
psql -d $DBNAME < ../db/dumps/development-data/v6-dump.sql
