DBNAME=fpa_test
SCHEMA_NAME=ml_app
DBOWNER=`whoami`

cd $(dirname $0)

sudo -u postgres psql -c "create database $DBNAME with owner $DBOWNER;"
sudo -u postgres psql -d fpa_test -c "create extension if not exists pgcrypto";
RAILS_ENV=test rake db:setup
RAILS_ENV=test rake db:seed
