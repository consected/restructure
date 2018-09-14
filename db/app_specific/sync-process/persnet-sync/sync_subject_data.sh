#! /bin/bash
#
# This script is run periodically to synchronize new PERSNET records, requested in Elaine AWS DB
# pulling matching PERSNET IDs and associated player_infos and player_contacts from Zeus FPHS DB
# and pushing this data to Elaine AWS DB
#
# NOTE: master_id on Zeus FPHS DB and Elaine AWS DB ** do not match **.
#       Only PERSNET ID can be used to match records in Zeus and Elaine
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
  rm $PERSNET_IDS_FILE 2> /dev/null
  rm $PERSNET_ASSIGNMENTS_FILE 2> /dev/null
  rm $PERSNET_PLAYER_INFOS_FILE 2> /dev/null
  rm $PERSNET_PLAYER_CONTACTS_FILE 2> /dev/null
  rm $PERSNET_ASSIGNMENTS_RESULTS_FILE 2> /dev/null
  rm $PSQLRESFL 2> /dev/null
  rm $RUN_SQL_FILE 2> /dev/null
}

function log {
  if [ "$RAILS_ENV" = 'development' ]
  then
    echo "`date +%m%d%Y%H%M` - $(basename $0) - $1"
  fi
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

if [ "$RAILS_ENV" == 'development' ] || [ "$EBENV" == 'DEV-fphs' ]
then
  BASEDIR='.'
  SCRDIR=${BASEDIR}
else
  BASEDIR=/FPHS/data/persnet/sync-process/persnet-sync
  SCRDIR=${BASEDIR}/scripts
fi

WORKINGDIR=${BASEDIR}/tmp
LOGDIR=${BASEDIR}/log
LOGFL=${LOGDIR}/sync_subject_data.log
PSQLRESFL=${WORKINGDIR}/.last_psql_error


. ../sync_db_connections.sh

log "Running in $(pwd)"
if [ -z "$ZEUS_DB" ]
then
  log "No matching environment"
  exit 1
fi

# Main SQL scripts
export PERSNET_ZEUS_FPHS_SQL_FILE=${SCRDIR}/run_sync_subject_data_fphs_db.sql
export PERSNET_AWS_SQL_FILE=${SCRDIR}/run_sync_subject_data_aws_db.sql
export PERSNET_ZEUS_FPHS_RESULTS_SQL_FILE=${SCRDIR}/run_sync_results_fphs_db.sql

# Temp files - can be anywhere - and will be cleaned up before and after use
export RUN_SQL_FILE=$WORKINGDIR/temp_persnet.sql
export PERSNET_IDS_FILE=$WORKINGDIR/remote_persnet_ids
export PERSNET_ASSIGNMENTS_FILE=$WORKINGDIR/zeus_persnet_assignments.csv
export PERSNET_PLAYER_INFOS_FILE=$WORKINGDIR/zeus_persnet_player_infos.csv
export PERSNET_PLAYER_CONTACTS_FILE=$WORKINGDIR/zeus_persnet_player_contacts.csv
export PERSNET_ASSIGNMENTS_RESULTS_FILE=${WORKINGDIR}/aws_persnet_assignments_results.csv

# Initially set the default schema for psql to be the AWS schema. This way, we do not need
# set search_path=... directly coded in the scripts
export PGOPTIONS=--search_path=$AWS_DB_SCHEMA


# ----> Cleanup from previous runs, just in case
cleanup


#================ Main Program ======================================

log 'Starting subject data sync.'

# ----> On Remote AWS DB
# Run find_new_remote_persnet_records() and copy to a CSV file (PERSNET_IDS_FILE)
# This returns a list of PERSNET IDs to be sync'd from the Zeus FPHS DB
#
log "Find remote PERSNET records"
echo "\copy (select * from find_new_remote_persnet_records()) to $PERSNET_IDS_FILE with (format csv, header true);" > $RUN_SQL_FILE 2> ${PSQLRESFL}
psql -d $AWS_DB -h $AWS_DB_HOST -U $AWS_DB_USER < $RUN_SQL_FILE
log_last_error


LINECOUNT="$(wc -l < $PERSNET_IDS_FILE)"
if [ -z "$LINECOUNT" ] || [ "$LINECOUNT" == '1' ]
then
  log "Nothing to transfer. Exiting."
  cleanup
  exit
else
  log "Number of records to transfer: $LINECOUNT"
fi



# ----> On Zeus FPHS DB
# Create a temp table temp_persnet_assignments to contain the PERSNET_IDS_FILE list of PERSNET IDs to sync
# Copy the PERSNET_IDS_FILE to temp_persnet_assignments
#
# For each temp_persnet_assignments record, update the record to include the Zeus master_id from the
# permanent persnet_assignments table
#
# For all master_id in temp_persnet_assignments table, copy matching player_infos and player_contacts records
# to CSV fields PERSNET_PLAYER_INFOS_FILE and PERSNET_PLAYER_CONTACTS_FILE
#
# Copy temp_persnet_assignments to PERSNET_ASSIGNMENTS_FILE

log "Match and export Zeus records"
envsubst < $PERSNET_ZEUS_FPHS_SQL_FILE > $RUN_SQL_FILE
PGOPTIONS=--search_path=$ZEUS_FPHS_DB_SCHEMA psql -d $ZEUS_DB -h $ZEUS_FPHS_DB_HOST -U $ZEUS_FPHS_DB_USER < $RUN_SQL_FILE 2> ${PSQLRESFL}
log_last_error

# ----> On Remote AWS DB
# Create temp tables for persnet_assignments, player_infos and player_contacts:
# temp_persnet_assignments, temp_player_infos and temp_player_contacts
#
# Copy PERSNET_IDS_FILE CSV data to temp_persnet_assignments
# Copy PERSNET_PLAYER_INFOS_FILE CSV data to temp_player_infos
# Copy PERSNET_PLAYER_CONTACTS_FILE CSV data to temp_player_contacts
#
# Run create_all_remote_persnet_records() to scan the temp_persnet_assignments list of PERSNET records, and for each
# to select the matching temp_player_infos and temp_player_contacts records
# (matched on Zeus master_id, since the temp_* tables still reference temp_persnet_assignments through Zeus master_id).
#
# Now for each PERSNET ID record call create_remote_persnet_record(match_persnet_id, new_player_info_record, new_player_contact_records)
# This creates the player_infos, player_contacts and updates activity_log_persnet_assignments, using the
# AWS DB master_id and user_id as a substitution for the original values pulled from Zeus.
#

log "Transfer matched records to remote DB"
envsubst < $PERSNET_AWS_SQL_FILE > $RUN_SQL_FILE
psql -d $AWS_DB -h $AWS_DB_HOST -U $AWS_DB_USER < $RUN_SQL_FILE 2> ${PSQLRESFL}
log_last_error

# Mark the transferred records as completed
log "Mark sync_statuses for transferred records"
envsubst < $PERSNET_ZEUS_FPHS_RESULTS_SQL_FILE > $RUN_SQL_FILE
PGOPTIONS=--search_path=$ZEUS_FPHS_DB_SCHEMA psql -d $ZEUS_DB -h $ZEUS_FPHS_DB_HOST -U $ZEUS_FPHS_DB_USER < $RUN_SQL_FILE 2> ${PSQLRESFL}
log_last_error


# ----> Cleanup
# cleanup
