#!/bin/bash

# Migrate the AWS production database by running the current version locally against the remote database
# Change the security group entry to allow access from your own IP address
# https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#SecurityGroups:search=sg-15079b63;sort=groupId

echo "Migrate the AWS production database by running the current version locally against the remote database"
echo "======================================================================================================"
echo "Enter app environment: stage or production"
read TEMP_ENV

if [ "$TEMP_ENV" == 'production' ]
then
  TEMP_DBNAME=fphs
fi

if [ "$TEMP_ENV" == 'stage' ]
then
  TEMP_DBNAME=fphs_test_ipa
fi

if [ -z "$TEMP_DBNAME" ]
then
  echo "Incorrect environment name: $TEMP_ENV"
  exit
fi

echo "Enter password for the $TEMP_ENV AWS database user FPHS:"
read -s -p "FPHS user password: " TEMP_DB_PW

echo
FPHS_POSTGRESQL_HOSTNAME=fphs-aws-db-prod01.c9dljdsduksr.us-east-1.rds.amazonaws.com \
FPHS_POSTGRESQL_DATABASE=fphs \
RAILS_ENV=production \
FPHS_POSTGRESQL_SCHEMA=ml_app \
FPHS_POSTGRESQL_USERNAME=fphs \
FPHS_POSTGRESQL_PORT=5432 \
FPHS_RAILS_SECRET_KEY_BASE=temp \
FPHS_RAILS_DEVISE_SECRET_KEY=temp \
FPHS_POSTGRESQL_PASSWORD="$TEMP_DB_PW" \
rake db:migrate

export PGPASSWORD="$TEMP_DB_PW"

psql -d fphs -h fphs-aws-db-prod01.c9dljdsduksr.us-east-1.rds.amazonaws.com -U fphs < fphs-sql/grant_roles_access_to_ml_app.sql
