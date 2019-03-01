#! /bin/bash

if [ -z "$1" ]
then
  echo Reset all otp secrets for admins or users
  echo Usage:
  echo "fphs_scripts/reset_all_otp_secrets.sh <admins | users>"
  echo The default environment "$RAILS_ENV" or production will be used, unless you set RAILS_ENV=yyy
  echo For example, to reset all users:
  echo   fphs-scripts/reset_all_otp_secrets.sh users
else
  if [ -z "$RAILS_ENV" ]
  then
    RAILS_ENV=production
  fi


  echo "$RAILS_ENV environment -- "
  echo "db host:  $FPHS_POSTGRESQL_HOSTNAME"
  echo "database: $FPHS_POSTGRESQL_DATABASE"
  HERE=$(dirname $0)/..

RAILS_ENV=$RAILS_ENV \
FPHS_POSTGRESQL_DATABASE=$FPHS_POSTGRESQL_DATABASE \
FPHS_POSTGRESQL_USERNAME=$FPHS_POSTGRESQL_USERNAME \
FPHS_POSTGRESQL_PASSWORD="$FPHS_POSTGRESQL_PASSWORD" \
FPHS_POSTGRESQL_PORT=$FPHS_POSTGRESQL_PORT \
FPHS_POSTGRESQL_HOSTNAME="$FPHS_POSTGRESQL_HOSTNAME" \
FPHS_POSTGRESQL_SCHEMA=$FPHS_POSTGRESQL_SCHEMA \
FPHS_RESET_USERS="$1" \
FPHS_ADMIN_SETUP=yes \
$HERE/script/rails runner $HERE/fphs-scripts/supporting/reset_all_otp_secrets.rb

fi
