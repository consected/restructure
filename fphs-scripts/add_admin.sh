#!/bin/bash

if [ -z "$1" ]
then
  echo Usage:
  echo "fphs_scripts/add_admin.sh <semicolon separated list of admin users to add or reset passwords>" 
  echo The default environment '$RAILS_ENV' will be used, unless you set RAILS_ENV=yyy
else
  if [ -z "$RAILS_ENV" ]
  then
    RAILS_ENV=production
  fi


  echo "$RAILS_ENV environment -- "
  HERE=$(dirname $0)/..

  RAILS_ENV=$RAILS_ENV FPHS_ADMIN_SETUP=yes FPHS_ACTION=add FPHS_ADMINS="$1" $HERE/script/rails runner $HERE/config/admin_setup.rb

fi
