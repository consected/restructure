#!/bin/bash

if [ -z "$1" ]; then
  echo Usage:
  echo "fphs_scripts/add_admin.sh <semicolon separated list of admin users to add or reset passwords>"
  echo "To reset the OTP secret as well as the password"
  echo "reset_secret=yes fphs_scripts/add_admin.sh <semicolon separated list of admin users to add or reset passwords>"
  echo The default environment "$RAILS_ENV" or production will be used, unless you set RAILS_ENV=yyy
else

  # Setup environment variables
  source app-scripts/get-aws-env-vars.sh

  if [ -z "$RAILS_ENV" ]; then
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
    FPHS_LOAD_APP_TYPES=1 \
    FPHS_ADMIN_SETUP=yes FPHS_ACTION=add FPHS_ADMINS="$1" $HERE/script/rails runner $HERE/app-scripts/supporting/admin_setup.rb

fi
