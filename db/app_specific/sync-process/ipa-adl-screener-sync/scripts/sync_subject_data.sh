#! /bin/bash
#
# This script is run periodically to synchronize new IPA ADL Informant Screener records
#
# NOTE: master_id on Zeus FPHS DB and Athena AWS DB ** do not match **.
#       Only IPA ID can be used to match records in Zeus and Athena
#
# Cron is setup to run on the VNC server.
# In file /etc/cron.d/fphs_sync:
# MAILTO=""
# PATH=/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/aws/bin:/root/bin
# * * * * * fphsetl cd /<location of this file> ; RAILS_ENV=production EBENV=PROD-fphs ./sync_subject_data.sh > /dev/null 2>&1
#
# Ensure that .pgpass is setup with the appropriate credentials
#
cd $(dirname $0)

if [ "$RAILS_ENV" == 'development' ]
then
  BASEDIR=..
else
  BASEDIR=/FPHS/data/ipa-adl-screener-sync
fi

WORKINGDIR=${BASEDIR}/tmp
LOGDIR=${BASEDIR}/log
SCRDIR=${BASEDIR}/scripts
LOGFL=${LOGDIR}/sync_subject_data.log
export PSQLRESFL=${WORKINGDIR}/.last_psql_error

. ${BASEDIR}/sync_db_connections.sh

function log {
  echo "`date +%m%d%Y%H%M` - $(basename $0) - $1" >> ${LOGFL}
}

if [ -z "$ZEUS_DB" ]
then
  log "No matching environment"
  exit 1
fi

# Main SQL scripts
export IPA_ZEUS_FPHS_SQL_FILE=${SCRDIR}/run_sync_subject_data_fphs_db.sql
export IPA_AWS_SQL_FILE=${SCRDIR}/run_sync_subject_data_aws_db.sql
export IPA_ZEUS_FPHS_RESULTS_SQL_FILE=${SCRDIR}/run_sync_results_fphs_db.sql

# Temp files - can be anywhere - and will be cleaned up before and after use
export IPA_SQL_FILE=${WORKINGDIR}/temp_ipa.sql
export IPA_ADL_SCREENERS_FILE=${WORKINGDIR}/zeus_ipa_adl_screeners.csv
export IPA_ASSIGNMENTS_RESULTS_FILE=${WORKINGDIR}/aws_ipa_assignments_results.csv

# Initially set the default schema for psql to be the AWS schema. This way, we do not need
# set search_path=... directly coded in the scripts
export PGOPTIONS=--search_path=$AWS_DB_SCHEMA

function cleanup {
  echo "Cleanup"
  rm $IPA_SQL_FILE 2> /dev/null
  rm $IPA_ADL_SCREENERS_FILE 2> /dev/null
  rm $IPA_ASSIGNMENTS_RESULTS_FILE 2> /dev/null
  rm $PSQLRESFL 2> /dev/null
}

function log_last_error {
  DATA=$(cat ${PSQLRESFL} 2> /dev/null)
  if [ ! -z "${DATA}" ]
  then
    log "${DATA}"
  fi
}

# ----> Cleanup from previous runs, just in case
cleanup

#================ Main Program ======================================

log 'Starting subject data sync.'

# ----> On Zeus FPHS DB
# Run run_sync_subject_data_fphs_db.sql
# Find the ADL Informant Screeners that have not already been transferred,
# based on the entries in sync_statuses
# Create a temp table temp_adl_screeners to contain the screener records to sync
#
# Copy the results to a CSV file: IPA_ADL_SCREENERS_FILE
#


log "Match and export FPHS records"
envsubst < $IPA_ZEUS_FPHS_SQL_FILE > $IPA_SQL_FILE

PGOPTIONS=--search_path=$ZEUS_FPHS_DB_SCHEMA psql -d $ZEUS_DB -h $ZEUS_FPHS_DB_HOST -U $ZEUS_FPHS_DB_USER < $IPA_SQL_FILE 2> ${PSQLRESFL}
log_last_error

LINECOUNT="$(wc -l < $IPA_ADL_SCREENERS_FILE)"
if [ -z "$LINECOUNT" ] || [ "$LINECOUNT" == '1' ]
then
  log "Nothing to transfer. Exiting."
  cleanup
  exit
fi


# ----> On Remote AWS DB
# Create temp tables for ipa_adl_screeners:
# temp_ipa_adl_screeners
#
# Copy IPA_ADL_SCREENERS_FILE CSV data to temp_ipa_adl_screeners
#
# Pull the IPA ID records for the screener records, then update the temp_ipa_adl_screeners
# table to include the new AWS master_id and user_id
#
# Now for each IPA ADL Screener record
# * insert a record into the AWS screeners table
# The trigger on_adl_screener_data_insert on this table
# * creates a record for activity_log_ipa_assignment_inex_checklists
# * creates a model_references entry to join the two records
# using the
# AWS DB master_id and user_id as a substitution for the original values pulled from Zeus.
#

log "Transfer matched records to remote DB"
envsubst < $IPA_AWS_SQL_FILE > $IPA_SQL_FILE
psql -d $AWS_DB -h $AWS_DB_HOST -U $AWS_DB_USER < $IPA_SQL_FILE 2> ${PSQLRESFL}
log_last_error

# Mark the transferred records as completed
log "Mark sync_statuses for transferred records"
envsubst < $IPA_ZEUS_FPHS_RESULTS_SQL_FILE > $IPA_SQL_FILE
PGOPTIONS=--search_path=$ZEUS_FPHS_DB_SCHEMA psql -d $ZEUS_DB -h $ZEUS_FPHS_DB_HOST -U $ZEUS_FPHS_DB_USER < $IPA_SQL_FILE 2> ${PSQLRESFL}
log_last_error

# ----> Cleanup
cleanup
