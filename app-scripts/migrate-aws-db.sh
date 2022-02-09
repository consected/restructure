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
  DB_SEARCH_PATH='ml_app,data_requests,ipa_ops,q1,q2,study_info,ref_data,dynamic,organization'
  TEMP_HOSTNAME='fphs-aws-db-prod01.c9dljdsduksr.us-east-1.rds.amazonaws.com'
fi

if [ "$TEMP_ENV" == 'filestore-production' ]; then
  TEMP_DBNAME=fphs
  DB_SEARCH_PATH='filestore,filestore_admin,ipa_ops,ml_app,ref_data,dynamic,organization'
  TEMP_HOSTNAME='fphs-aws-db-prod01.c9dljdsduksr.us-east-1.rds.amazonaws.com'
fi

if [ "$TEMP_ENV" == 'zeus-production' ]; then
  TEMP_DBNAME=fphs
  DB_SEARCH_PATH='ml_app,ref_data,dynamic'
  TEMP_HOSTNAME='fphs-zeus-db-prod01.cqtftnqosfiy.us-east-1.rds.amazonaws.com,organization'
fi

if [ "$TEMP_ENV" == 'athena-stage' ]; then
  TEMP_DBNAME=fphs_sleep_test
  DB_SEARCH_PATH='filestore,filestore_admin,ml_app,ref_data,dynamic,organization'
  TEMP_HOSTNAME='fphs-aws-db-prod01.c9dljdsduksr.us-east-1.rds.amazonaws.com'
fi

if [ "$TEMP_ENV" == 'athena-demo' ]; then
  TEMP_DBNAME=ebdb
  DB_SEARCH_PATH='ml_app,data_requests,ipa_ops,q1,q2,study_info,ref_data,dynamic,organization'
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

echo "Specify the schema names (space separated) to apply GRANTs to"
read SCHEMA_NAMES

echo

echo "Allow migration / rollback to drop columns? Enter 'true' to allow."
read ALLOW_DROP_COLUMNS
if [ "$ALLOW_DROP_COLUMNS" == 'true' ]; then
  export ALLOW_DROP_COLUMNS
  export STEPS='STEP=1'
  echo "Will drop columns if needed."
  echo "Migration limited to 1 step. Re-run to check the next one"
else
  if [ "$MODE" == 'rollback' ]; then
    echo "Rollback how many steps? (default 1)"
    read REQSTEPS
    if [ "${REQSTEPS}" ]; then
      export STEPS="STEP=${REQSTEPS}"
    fi
  fi
fi

echo

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
  bundle exec rake db:${MODE} ${STEPS}

export PGPASSWORD="$TEMP_DB_PW"

for SCHEMA_NAME in $SCHEMA_NAMES; do

  psql -d $TEMP_DBNAME -h $TEMP_HOSTNAME -U $DB_USERNAME < ../fphs-app-configs/fphs-sql/grant_roles_access_to_ml_app.sql

  if [ "$TEMP_ENV" == 'filestore-production' ]; then
    psql -d $TEMP_DBNAME -h $TEMP_HOSTNAME -U $DB_USERNAME < ../fphs-app-configs/fphs-sql/grant_roles_access_to_filestore.sql
  fi

  if [ "$TEMP_ENV" == 'zeus-production' ]; then
    psql -d $TEMP_DBNAME -h $TEMP_HOSTNAME -U $DB_USERNAME < ../fphs-app-configs/fphs-sql/grant_roles_access_to_zeus.sql
  fi

  if [ -f "fphs-sql/grant_roles_access_to_${SCHEMA_NAME}.sql" ]; then
    psql -d $TEMP_DBNAME -h $TEMP_HOSTNAME -U $DB_USERNAME < ../fphs-app-configs/fphs-sql/grant_roles_access_to_${SCHEMA_NAME}.sql
    continue
  fi

  psql -d $TEMP_DBNAME -h $TEMP_HOSTNAME -U $DB_USERNAME 2>&1 << EOF
REVOKE ALL ON SCHEMA ${SCHEMA_NAME} FROM fphs;
GRANT ALL ON SCHEMA ${SCHEMA_NAME} TO fphs;
GRANT USAGE ON SCHEMA ${SCHEMA_NAME} TO fphsadm;
GRANT USAGE ON SCHEMA ${SCHEMA_NAME} TO fphsusr;
GRANT USAGE ON SCHEMA ${SCHEMA_NAME} TO fphsetl;
GRANT ALL ON ALL TABLES IN SCHEMA ${SCHEMA_NAME} TO fphs;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ${SCHEMA_NAME} TO fphsusr;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ${SCHEMA_NAME} TO fphsetl;
GRANT SELECT, INSERT, DELETE, TRUNCATE, UPDATE ON ALL TABLES IN SCHEMA ${SCHEMA_NAME} TO fphsadm;
GRANT ALL ON ALL SEQUENCES IN SCHEMA ${SCHEMA_NAME} TO fphs;
GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA ${SCHEMA_NAME} TO fphsusr;
GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA ${SCHEMA_NAME} TO fphsetl;
GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA ${SCHEMA_NAME} TO fphsadm;
DO \$body\$
BEGIN
  IF EXISTS (
    SELECT * FROM pg_catalog.pg_roles WHERE rolname = 'fphsrailsapp'
    ) THEN
GRANT USAGE ON SCHEMA ${SCHEMA_NAME} TO fphsrailsapp;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ${SCHEMA_NAME} TO fphsrailsapp;
GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA ${SCHEMA_NAME} TO fphsrailsapp;
END IF;
END \$body\$; 
DO \$body\$
BEGIN
  IF EXISTS (
    SELECT * FROM pg_catalog.pg_roles WHERE rolname = 'fphsrailsapp1'
    ) THEN
GRANT USAGE ON SCHEMA ${SCHEMA_NAME} TO fphsrailsapp1;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ${SCHEMA_NAME} TO fphsrailsapp1;
GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA ${SCHEMA_NAME} TO fphsrailsapp1;
END IF;
END \$body\$;
EOF

done

echo "Note:"
echo "For Athena or Filestore, it may be necessary to force the migrations that have been completed directly in the database"
echo "  rails db"
echo "  set search_path=$DB_SEARCH_PATH;"
echo "  insert into schema_migrations
  (version)
  values
  (20181113175031),
  (20181113180608);"
