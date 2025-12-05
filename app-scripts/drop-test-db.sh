#!/bin/bash
# Drop numbered test databases, for parallel testing
# Usage
# app-scripts/drop-test-db.sh <num_dbs>
# or with inline environment variables
# DB_BASE_NAME=<val> USE_PG_HOST=<val> USE_PG_UNAME=<val> app-scripts/create-test-db.sh <num_dbs>
# Arguments:
# num_dbs: Specify the number of databases to drop - defaults to number of vCPUs
# Environment variables - all are optional:
# DB_BASE_NAME - Base name for the database - defaults to restr
# USE_PG_HOST - Use IP rather than local (sockets) to connect to database.
#               If not set, the OS postgres user will be used for a local connection, and requires sudo
# USE_PG_UNAME - If USE_PG_HOST is set, optionally specify the database user (default: postgres)

DB_BASE_NAME=${DB_BASE_NAME:=restr}

function drop() {

  DBNAME=${DB_BASE_NAME}_test${DBNUM}
  APPENV=test
  SCHEMA_NAME=ml_app
  DBOWNER=$(whoami)

  if [ "${USE_PG_HOST}" ] || [ "${USE_PG_UNAME}" ]; then
    USE_PG_UNAME=${USE_PG_UNAME:=postgres}
    PSQL_ARGS="-U ${USE_PG_UNAME}"
    if [ "${USE_PG_HOST}" ]; then
      PSQL_ARGS="${PSQL_ARGS} -h ${USE_PG_HOST}"
    fi
    psql -c "drop database $DBNAME" $PSQL_ARGS
  else
    sudo -u postgres psql -c "drop database $DBNAME;"
  fi

}

if [ -z $1 ]; then
  PARALLEL=$(nproc)
else
  PARALLEL=$1
fi

if [ -z ${PARALLEL} ]; then
  echo "Single drop"
  drop
else
  echo "Drop ${PARALLEL} databases"
  for i in $(seq 1 ${PARALLEL}); do
    if [ ${i} == 1 ]; then
      DBNUM=''
    else
      DBNUM=${i}
    fi
    drop
  done
fi

# Clean up the temporary nfs_store directories
rm -rf /var/tmp/nfs_store_tmp*
rm -rf /var/tmp/nfs_store_test*
