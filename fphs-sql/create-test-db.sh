DBNAME=fpa_test
SCHEMA_NAME=ml_app
DBOWNER=`whoami`

cd $(dirname $0)

sudo -u postgres psql -c "create database $DBNAME with owner $DBOWNER;"
RAILS_ENV=test rake db:setup
