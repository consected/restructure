#! /bin/bash

if [ -z "$1" ]
then
  echo Validate an electronically signed document file
  echo Usage:
  echo "fphs_scripts/validate_file_signature.sh <path to document>"
  echo The default environment "$RAILS_ENV" or production will be used, unless you set RAILS_ENV=yyy
  echo For example, to validate a document stored in the filestore filesystem:
  echo   fphs-scripts/validate_file_signature.sh /mnt/fphsfs/gid600/app-type-30/containers/207\ --\ e-signature/signed\ document\ by\ phil_ayres\@test.com\ at\ 2019-02-25T14\:09\:53Z.html
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
FPHS_VALIDATE_FILENAME="$1" \
$HERE/script/rails runner $HERE/fphs-scripts/supporting/validate_file_signature.rb

fi
