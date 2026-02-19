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
DBNUM=${DBNUM:=${TEST_ENV_NUMBER}}
DBOWNER=${DBOWNER:=$(whoami)}

export PGOPTIONS='--client-min-messages=warning'

function setup() {

  DBNAME=${DB_BASE_NAME}${TEST_ENV_SET}_test${DBNUM}
  echo "Creating: ${DBNAME}"
  cd "$(dirname "${BASEDIR}")" || return

  if [ "${USE_PG_HOST}" ] || [ "${USE_PG_UNAME}" ]; then
    export USE_PG_UNAME=${USE_PG_UNAME:=postgres}
    PSQL_ARGS="-U ${USE_PG_UNAME}"
    if [ "${USE_PG_HOST}" ]; then
      PSQL_ARGS="${PSQL_ARGS} -h ${USE_PG_HOST}"
    fi
    psql -c "create extension if not exists pgcrypto;" $PSQL_ARGS > /dev/null
    psql -c "create database $DBNAME;" $PSQL_ARGS > /dev/null
    for user in fphsetl fphs fphsrailsapp fphsadm fphsusr; do
      psql -c "create user ${user} password 'fphs';" $PSQL_ARGS > /dev/null
    done
    psql -d "$DBNAME" $PSQL_ARGS < "../db/structure.sql" > /dev/null
    psql -d "$DBNAME" -c "create schema if not exists bulk_msg;" $PSQL_ARGS > /dev/null
    psql -d "$DBNAME" -c "create schema if not exists ref_data;" $PSQL_ARGS > /dev/null
  else
    sudo -u postgres psql -c "create extension if not exists pgcrypto;" > /dev/null
    sudo -u postgres psql -c "create database $DBNAME with owner $DBOWNER;" > /dev/null
    for user in fphsetl fphs fphsrailsapp fphsadm fphsusr; do
      sudo -u postgres psql -c "create user ${user} password 'fphs';" > /dev/null
    done
    psql -d "$DBNAME" < "../db/structure.sql" > /dev/null
    psql -d "$DBNAME" -c "create schema if not exists bulk_msg;" > /dev/null
    psql -d "$DBNAME" -c "create schema if not exists ref_data;" > /dev/null
  fi

  RAILS_ENV=test TEST_ENV_NUMBER=${DBNUM} bundle exec rails db:seed > /dev/null
}

if [ -z $1 ]; then
  PARALLEL=$(nproc)
else
  PARALLEL=$1
fi

if [ -z "${PARALLEL}" ] || [ "${PARALLEL}" == '1' ]; then
  echo "Single setup: ${DB_BASE_NAME}${TEST_ENV_SET}_test${DBNUM}"
  setup
else
  echo "Setup ${PARALLEL} databases: ${DB_BASE_NAME}${TEST_ENV_SET}_test<n>"
  for i in $(seq 1 "${PARALLEL}"); do
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
