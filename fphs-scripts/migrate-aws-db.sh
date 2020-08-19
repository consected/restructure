#!/bin/bash

# Migrate the AWS production database by running the current version locally against the remote database
# Change the security group entry to allow access from your own IP address
# https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#SecurityGroups:search=sg-15079b63;sort=groupId

echo "Migrate the AWS database by running the current version locally against the remote database"
echo "==========================================================================================="

echo ""
echo "========================================="
echo "Enter app environment: athena-demo, athena-stage, athena-production, filestore-production"

read TEMP_ENV

DB_USERNAME=fphs
export FILESTORE_CONFIG_SKIP=true

if [ "$TEMP_ENV" == 'athena-production' ]; then
  TEMP_DBNAME=fphs
  DB_SEARCH_PATH='ml_app'
  TEMP_HOSTNAME='fphs-aws-db-prod01.c9dljdsduksr.us-east-1.rds.amazonaws.com'
fi

if [ "$TEMP_ENV" == 'filestore-production' ]; then
  TEMP_DBNAME=fphs
  DB_SEARCH_PATH='filestore,filestore_admin,ipa_ops,ml_app'
  TEMP_HOSTNAME='fphs-aws-db-prod01.c9dljdsduksr.us-east-1.rds.amazonaws.com'
fi

if [ "$TEMP_ENV" == 'zeus-production' ]; then
  TEMP_DBNAME=fphs
  DB_SEARCH_PATH='ml_app'
  TEMP_HOSTNAME='fphs-zeus-db-prod01.cqtftnqosfiy.us-east-1.rds.amazonaws.com'
fi

if [ "$TEMP_ENV" == 'athena-stage' ]; then
  TEMP_DBNAME=fphs_sleep_test
  DB_SEARCH_PATH='filestore,filestore_admin,ml_app'
  TEMP_HOSTNAME='fphs-aws-db-prod01.c9dljdsduksr.us-east-1.rds.amazonaws.com'
fi

if [ "$TEMP_ENV" == 'athena-demo' ]; then
  TEMP_DBNAME=ebdb
  DB_SEARCH_PATH='ml_app,data_requests, ipa_ops,q1,q2'
  TEMP_HOSTNAME='fphs-aws-db-dev01.c9dljdsduksr.us-east-1.rds.amazonaws.com'
fi

if [ -z "$TEMP_DBNAME" ]; then
  echo "Incorrect environment name: $TEMP_ENV"
  exit
fi

echo "Enter password for the $TEMP_ENV AWS database user FPHS:"
read -s -p "FPHS user password: " TEMP_DB_PW
echo
echo "migrate or rollback?"
read MODE
echo "Specify a migration path MIG_PATH or just hit enter"
read MIG_PATH
if [ "$MIG_PATH" ]; then
  export MIG_PATH
fi

echo

MIG_PATH=$MIG_PATH \
  FPHS_POSTGRESQL_HOSTNAME=$TEMP_HOSTNAME \
  FPHS_POSTGRESQL_DATABASE=$TEMP_DBNAME \
  RAILS_ENV=production \
  FPHS_POSTGRESQL_SCHEMA="$DB_SEARCH_PATH" \
  FPHS_POSTGRESQL_USERNAME="$DB_USERNAME" \
  FPHS_POSTGRESQL_PORT=5432 \
  FPHS_RAILS_SECRET_KEY_BASE=temp \
  FPHS_RAILS_DEVISE_SECRET_KEY=temp \
  FPHS_POSTGRESQL_PASSWORD="$TEMP_DB_PW" \
  FPHS_LOAD_APP_TYPES=1 \
  bundle exec rake db:${MODE}

export PGPASSWORD="$TEMP_DB_PW"

psql -d $TEMP_DBNAME -h $TEMP_HOSTNAME -U fphs < fphs-sql/grant_roles_access_to_ml_app.sql

if [ "$TEMP_ENV" == 'filestore-production' ]; then
  psql -d $TEMP_DBNAME -h $TEMP_HOSTNAME -U fphs < fphs-sql/grant_roles_access_to_filestore.sql
fi

if [ "$TEMP_ENV" == 'zeus-production' ]; then
  psql -d $TEMP_DBNAME -h $TEMP_HOSTNAME -U fphs < fphs-sql/grant_roles_access_to_zeus.sql
fi

echo "Note:"
echo "For Athena or Filestore, it may be necessary to force the migrations that have been completed directly in the database"
echo "  rails db"
echo "  set search_path=$DB_SEARCH_PATH;"
echo "  insert into schema_migrations
  (version)
  values
  (20181113175031),
  (20181113180608);"
