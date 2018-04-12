DBNAME=fphs_demo
DBOWNER=`whoami`

cd $(dirname $0)

sudo -u postgres psql -c "create database $DBNAME with owner $DBOWNER;"
sudo -u postgres psql < create_roles.sql
psql -d $DBNAME < ../db/dumps/development-data/v6-dump.sql
