DBNAME=fpa_test
APPENV=test
SCHEMA_NAME=ml_app
DBOWNER=`whoami`

cd $(dirname $0)

sudo -u postgres psql -c "create database $DBNAME with owner $DBOWNER;"
sudo -u postgres psql -d $DBNAME -c "create schema $SCHEMA_NAME;"
sudo -u postgres psql -d $DBNAME -c "set search_path=$SCHEMA_NAME; create extension if not exists pgcrypto;"
RAILS_ENV=$APPENV FPHS_POSTGRESQL_DATABASE=$DBNAME rake db:setup
RAILS_ENV=$APPENV FPHS_POSTGRESQL_DATABASE=$DBNAME rake db:seed
