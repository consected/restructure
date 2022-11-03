#!/bin/bash
# Create numbered test databases, for parallel testing
# Usage
# app-scripts/create-test-db.sh <num_dbs>
# or with inline environment variables
# DB_BASE_NAME=<val> USE_PG_HOST=<val> USE_PG_UNAME=<val> app-scripts/create-test-db.sh <num_dbs>
# Arguments:
# num_dbs: Specify the number of databases to create - defaults to number of vCPUs
# Environment variables - all are optional:
# DB_BASE_NAME - Base name for the database - defaults to restr
# USE_PG_HOST - Use IP rather than local (sockets) to connect to database.
#               If not set, the OS postgres user will be used for a local connection, and requires sudo
# USE_PG_UNAME - If USE_PG_HOST is set, optionally specify the database user (default: postgres)

BASEDIR=$0
DB_BASE_NAME=${DB_BASE_NAME:=restr}
DBOWNER=${DBOWNER:=$(whoami)}

function setup() {

  DBNAME=${DB_BASE_NAME}_test${DBNUM}

  cd $(dirname ${BASEDIR})

  if [ "${USE_PG_HOST}" ]; then
    USE_PG_UNAME=${USE_PG_UNAME:=postgres}
    psql -c "create extension if not exists pgcrypto;" -U ${USE_PG_UNAME} -h "${USE_PG_HOST}"
    psql -c "create database $DBNAME;"
    psql -d $DBNAME -U ${USE_PG_UNAME} -h "${USE_PG_HOST}" < "../db/structure.sql"
    psql -d $DBNAME -c "create schema if not exists bulk_msg;" -U ${USE_PG_UNAME} -h "${USE_PG_HOST}"
    psql -d $DBNAME -c "create schema if not exists ref_data;" -U ${USE_PG_UNAME} -h "${USE_PG_HOST}"
  else
    sudo -u postgres psql -c "create extension if not exists pgcrypto;"
    sudo -u postgres psql -c "create database $DBNAME with owner $DBOWNER;"
    psql -d $DBNAME < "../db/structure.sql"
    psql -d $DBNAME -c "create schema if not exists bulk_msg;"
    psql -d $DBNAME -c "create schema if not exists ref_data;"
  fi

  RAILS_ENV=test TEST_ENV_NUMBER=${DBNUM} bundle exec rails db:seed
}

if [ -z $1 ]; then
  PARALLEL=$(nproc)
else
  PARALLEL=$1
fi

if [ -z ${PARALLEL} ]; then
  echo "Single setup"
  setup
else
  echo "Setup ${PARALLEL} databases"
  for i in $(seq 1 ${PARALLEL}); do
    if [ ${i} == 1 ]; then
      DBNUM=''
    else
      DBNUM=${i}
    fi
    if [ "${i}" == "${PARALLEL}" ]; then
      setup
    else
      setup &
    fi
  done

  # Ensure entries have been made in .pgpass for these DBs
fi
