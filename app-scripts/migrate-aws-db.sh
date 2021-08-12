#!/bin/bash

# Migrate the AWS production or staging database by running the current version locally against the remote database
# Change the security group entry to allow access from your own IP address
# https://console.aws.amazon.com/ec2/v2/home

echo "Migrate a database by running the current version locally against the remote database"
echo "======================================================================================================"
echo "Enter the DB host name"
read DB_HOST
echo
echo "Enter the DB name"
read DB_NAME
echo
echo "Enter the DB admin username"
read DB_USER
echo

echo "Enter the DB app username"
read DB_APP_USER
echo

echo "Enter password for the user"
read -s -p "$DB_USER user password: " TEMP_DB_PW
echo

echo "Specify a migration path MIG_PATH or just hit enter"
read MIG_PATH
if [ "$MIG_PATH" ]; then
  export MIG_PATH
fi
echo

echo "Specify the schema name (leave blank to migrate the main schema)"
read SCHEMA_NAME
BASE_SCHEMA_PATH='ml_app,ref_data,dynamic'
if [ "$SCHEMA_NAME" ]; then
  DB_SCHEMA="${BASE_SCHEMA_PATH},${SCHEMA_NAME}"
else
  DB_SCHEMA=${BASE_SCHEMA_PATH}
fi

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

FPHS_POSTGRESQL_HOSTNAME=$DB_HOST \
FPHS_POSTGRESQL_DATABASE=$DB_NAME \
RAILS_ENV=production \
FPHS_POSTGRESQL_SCHEMA=$DB_SCHEMA \
FPHS_POSTGRESQL_USERNAME=$DB_USER \
FPHS_POSTGRESQL_PORT=5432 \
FPHS_RAILS_SECRET_KEY_BASE=temprake1238761826381263ksjafhkjahkjfhjkshfahasjkrywuieryiweh \
FPHS_RAILS_DEVISE_SECRET_KEY=temprake1238761826381263ksjafhkjahkjfhjkshfahasjkrywuieryiweh \
FPHS_POSTGRESQL_PASSWORD="$TEMP_DB_PW" \
FPHS_LOAD_APP_TYPES=1 \
rake db:migrate


PGPASSWORD="$TEMP_DB_PW" psql -d $DB_NAME -h $DB_HOST -U $DB_USER 2>&1 << EOF
GRANT USAGE ON SCHEMA ${DB_SCHEMA} TO ${DB_APP_USER};
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ${DB_SCHEMA} TO ${DB_APP_USER};
GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA ${DB_SCHEMA} TO ${DB_APP_USER};
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA ${DB_SCHEMA} TO ${DB_APP_USER};
EOF
