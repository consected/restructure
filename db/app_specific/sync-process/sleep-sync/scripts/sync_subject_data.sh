#! /bin/bash
#
# This script is run periodically to synchronize new SLEEP records, requested in Athena AWS DB
# pulling matching SLEEP IDs and associated player_infos and player_contacts from Zeus FPHS DB
# and pushing this data to Athena AWS DB
#
# NOTE: master_id on Zeus FPHS DB and Athena AWS DB ** do not match **.
#       Only SLEEP ID can be used to match records in Zeus and Athena
#
# Cron is setup to run on the VNC server.
# In file /etc/cron.d/fphs_sync:
# MAILTO=""
# PATH=/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/aws/bin:/root/bin
# * * * * * fphsetl cd /<location of this file> ; RAILS_ENV=production EBENV=PROD-fphs ./sync_subject_data.sh > /dev/null 2>&1
#
# Ensure that .pgpass is setup with the appropriate credentials
#

function cleanup {
  echo "Cleanup"
  rm $SLEEP_SQL_FILE 2> /dev/null
  rm $SLEEP_ASSIGNMENTS_FILE 2> /dev/null
  rm $SLEEP_PLAYER_INFOS_FILE 2> /dev/null
  rm $SLEEP_PLAYER_CONTACTS_FILE 2> /dev/null
  rm $SLEEP_ADDRESSES_FILE 2> /dev/null
  rm $SLEEP_ASSIGNMENTS_RESULTS_FILE 2> /dev/null
  rm $PSQLRESFL 2> /dev/null
}

function log {
  echo "`date +%m%d%Y%H%M` - $(basename $0) - $1" >> ${LOGFL}
}

function log_last_error {
  DATA=$(cat ${PSQLRESFL} 2> /dev/null)
  if [ ! -z "${DATA}" ]
  then
    log "${DATA}"
  fi
}



cd $(dirname $0)
if [ "$RAILS_ENV" == 'development' ]
then
  BASEDIR=..
  pwd
else
  BASEDIR=/FPHS/data/sleep-sync
fi
WORKINGDIR=${BASEDIR}/tmp
LOGDIR=${BASEDIR}/log
SCRDIR=${BASEDIR}/scripts
LOGFL=${LOGDIR}/sync_subject_data.log
export PSQLRESFL=${WORKINGDIR}/.last_psql_error


if [ "$RAILS_ENV" == 'development' ]
then
  . ${BASEDIR}/../sync_db_connections.sh
else
  . ${BASEDIR}/sync_db_connections.sh
fi

if [ -z "$ZEUS_DB" ]
then
  log "No matching environment"
  exit 1na
fi

# Configurations
if [ "$RAILS_ENV" == 'development' ]
then
  export SUBPROCESS_ID=221
fi

if [ "$RAILS_ENV" == 'production' ]
then

  if [ "$EBENV" == 'DEV-fphs' ]
  then
    export SUBPROCESS_ID=221
  fi

  if [ "$EBENV" == 'TEST-aws' ]
  then
    export SUBPROCESS_ID=216
  fi

  if [ "$EBENV" == 'PROD-fphs' ]
  then
    export SUBPROCESS_ID=126
  fi
fi

# Main SQL scripts
export SLEEP_ZEUS_FPHS_SQL_FILE=${SCRDIR}/run_sync_subject_data_fphs_db.sql
export SLEEP_AWS_SQL_FILE=${SCRDIR}/run_sync_subject_data_aws_db.sql
export SLEEP_ZEUS_FPHS_RESULTS_SQL_FILE=${SCRDIR}/run_sync_results_fphs_db.sql

# Temp files - can be anywhere - and will be cleaned up before and after use
export SLEEP_SQL_FILE=${WORKINGDIR}/temp_sleep.sql
export SLEEP_ASSIGNMENTS_FILE=${WORKINGDIR}/zeus_sleep_assignments.csv
export SLEEP_PLAYER_INFOS_FILE=${WORKINGDIR}/zeus_sleep_player_infos.csv
export SLEEP_PLAYER_CONTACTS_FILE=${WORKINGDIR}/zeus_sleep_player_contacts.csv
export SLEEP_ADDRESSES_FILE=${WORKINGDIR}/zeus_sleep_addresses.csv
export SLEEP_ASSIGNMENTS_RESULTS_FILE=${WORKINGDIR}/aws_sleep_assignments_results.csv

# ----> Cleanup from previous runs, just in case
cleanup

#================ Main Program ======================================

log 'Starting subject data sync.'

# ----> On Zeus FPHS DB
# Run run_sync_subject_data_fphs_db.sql
# Create a temp table temp_sleep_assignments to contain the  SLEEP IDs to sync, based on a simple query
#
# For all master_id in temp_sleep_assignments table, copy matching player_infos, player_contacts and addresses records
# to CSV files SLEEP_PLAYER_INFOS_FILE, SLEEP_PLAYER_CONTACTS_FILE AND SLEEP_ADDRESSES_FILE
#
# Copy temp_sleep_assignments to SLEEP_ASSIGNMENTS_FILE

log "Match and export Zeus records"
envsubst < $SLEEP_ZEUS_FPHS_SQL_FILE > $SLEEP_SQL_FILE

PGOPTIONS=--search_path=$ZEUS_FPHS_DB_SCHEMA psql -d $ZEUS_DB -h $ZEUS_FPHS_DB_HOST -U $ZEUS_FPHS_DB_USER < $SLEEP_SQL_FILE 2> ${PSQLRESFL}
log_last_error

LINECOUNT="$(wc -l < $SLEEP_ASSIGNMENTS_FILE)"
if [ -z "$LINECOUNT" ] || [ "$LINECOUNT" == '1' ]
then
  log "Nothing to transfer. Exiting."
  cleanup
  exit
fi


# ----> On Remote AWS DB
# Create temp tables for sleep_assignments, player_infos, player_contacts and addresses:
# temp_sleep_assignments, temp_player_infos, temp_player_contacts, temp_addresses
#
# Copy SLEEP_ASSIGNMENTS_FILE CSV data to temp_sleep_assignments
# Copy SLEEP_PLAYER_INFOS_FILE CSV data to temp_player_infos
# Copy SLEEP_PLAYER_CONTACTS_FILE CSV data to temp_player_contacts
# Copy SLEEP_ADDRESSES_FILE CSV data to temp_addresses
#
# Run create_all_remote_sleep_records() to scan the temp_sleep_assignments list of SLEEP records, and for each
# to select the matching temp_player_infos and temp_player_contacts records
# (matched on Zeus master_id, since the temp_* tables still reference temp_sleep_assignments through Zeus master_id).
#
# Now for each SLEEP ID record call create_remote_sleep_record(match_sleep_id, new_player_info_record, new_player_contact_records)
# This creates the player_infos, player_contacts and updates activity_log_sleep_assignments, using the
# AWS DB master_id and user_id as a substitution for the original values pulled from Zeus.
#

log "Transfer matched records to remote DB"
envsubst < $SLEEP_AWS_SQL_FILE > $SLEEP_SQL_FILE
PGOPTIONS=--search_path=$AWS_DB_SCHEMA psql -d $AWS_DB -h $AWS_DB_HOST -U $AWS_DB_USER < $SLEEP_SQL_FILE 2> ${PSQLRESFL}
log_last_error

# Mark the transferred records as completed
log "Mark sync_statuses for transferred records"
envsubst < $SLEEP_ZEUS_FPHS_RESULTS_SQL_FILE > $SLEEP_SQL_FILE
PGOPTIONS=--search_path=$ZEUS_FPHS_DB_SCHEMA psql -d $ZEUS_DB -h $ZEUS_FPHS_DB_HOST -U $ZEUS_FPHS_DB_USER < $SLEEP_SQL_FILE 2> ${PSQLRESFL}
log_last_error

# ----> Cleanup
cleanup
