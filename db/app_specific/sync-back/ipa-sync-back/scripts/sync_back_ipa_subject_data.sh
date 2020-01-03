#! /bin/bash
#
# This script is run periodically to synchronize new IPA records, requested in Athena AWS DB
# pulling matching IPA IDs and associated player_infos and player_contacts from Zeus FPHS DB
# and pushing this data to Athena AWS DB
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
  BASEDIR=$(pwd)/..
else
  BASEDIR=/FPHS/data/ipa-sync-back
fi
export SBPULLDIR=${BASEDIR}/..

###### Pull specific information and functions #############

export STUDY=IPA
export SBSHARE=${SBPULLDIR}/sync_back_functions.sh
export SUBPROCESS_ID=216


################## Setup shared functions and variables, then start the process
# Source the shared functions
. ${SBSHARE}

setup_process

log INFO "##################################"
log INFO "Starting Sync Back ${STUDY}"


# Dev specific Configurations
if [ "$RAILS_ENV" == 'development' ]
then
  export SUBPROCESS_ID=221
fi

if [ "$RAILS_ENV" == 'production' ] && [ "$EBENV" == 'DEV-fphs' ]
then
  export SUBPROCESS_ID=221
fi

# Main SQL scripts
export ATHENA_SQL_FILE=${SCRDIR}/run_sync_subject_data_from_athena_db.sql
export TO_FPHS_SQL_FILE=${SCRDIR}/run_sync_subject_data_to_fphs_db.sql
export ATHENA_RESULTS_SQL_FILE=${SCRDIR}/run_sync_results_athena_db.sql

# Temp files - can be anywhere - and will be cleaned up before and after use
export CURRENT_SQL_FILE=${WORKINGDIR}/temp_working_file.sql
export ASSIGNMENTS_FILE=${WORKINGDIR}/athena_assignments.csv
export PLAYER_INFOS_FILE=${WORKINGDIR}/athena_player_infos.csv
export PLAYER_CONTACTS_FILE=${WORKINGDIR}/athena_player_contacts.csv
export ADDRESSES_FILE=${WORKINGDIR}/athena_addresses.csv
export EVENTS_FILE=${WORKINGDIR}/athena_events.csv
export ASSIGNMENTS_RESULTS_FILE=${WORKINGDIR}/fphs_assignments_results.csv

# ----> Cleanup from previous runs, just in case
cleanup

#================ Main Program ======================================

log INFO 'Starting subject data sync.'

# ----> On Zeus FPHS DB
# Run run_sync_subject_data_fphs_db.sql
# Create a temp table temp_assignments to contain the IPA IDs to sync, based on a simple query
#
# For all master_id in temp_assignments table, copy matching player_infos, player_contacts, addresses, AL events records
# to CSV files PLAYER_INFOS_FILE, PLAYER_CONTACTS_FILE, ADDRESSES_FILE, EVENTS_FILE
#
# Copy temp_assignments to ASSIGNMENTS_FILE

log INFO "Match and export Athena records"
envsubst < $ATHENA_SQL_FILE > $CURRENT_SQL_FILE

PGOPTIONS=--search_path=$ZEUS_FPHS_DB_SCHEMA psql -d $AWS_DB -h $AWS_DB_HOST -U $AWS_DB_USER -v ON_ERROR_STOP=1 < $CURRENT_SQL_FILE 2> ${PSQLRESFL}
log_last_error_and_exit

LINECOUNT="$(wc -l < $ASSIGNMENTS_FILE)"
if [ -z "$LINECOUNT" ] || [ "$LINECOUNT" == '1' ]
then
  log INFO "Nothing to transfer. Exiting."
  cleanup
  exit
else
  log INFO "Records found to transfer: ${LINECOUNT}"
fi

# ----> On Remote AWS DB
# Create temp tables for ipa_assignments, player_infos, player_contacts and addresses:
# temp_assignments, temp_player_infos, temp_player_contacts, temp_addresses
#
# Copy ASSIGNMENTS_FILE CSV data to temp_assignments
# Copy PLAYER_INFOS_FILE CSV data to temp_player_infos
# Copy PLAYER_CONTACTS_FILE CSV data to temp_player_contacts
# Copy ADDRESSES_FILE CSV data to temp_addresses
# Copy EVENTS_FILE data to temp_events
#
# Run create_all_remote_records() to scan the temp_assignments list of IPA records, and for each
# to select the matching temp_player_infos and temp_player_contacts records
# (matched on Zeus master_id, since the temp_* tables still reference temp_assignments through Zeus master_id).
#
# Now for each IPA ID record call create_remote_record(match_id, new_player_info_record, new_player_contact_records)
# This creates the player_infos, player_contacts and updates activity_log_assignments, using the
# AWS DB master_id and user_id as a substitution for the original values pulled from Zeus.
#

log INFO "Transfer matched records to FPHS DB"
envsubst < $TO_FPHS_SQL_FILE > $CURRENT_SQL_FILE
PGOPTIONS=--search_path=$AWS_DB_SCHEMA psql -d $ZEUS_DB -h $ZEUS_FPHS_DB_HOST -U $ZEUS_FPHS_DB_USER -v ON_ERROR_STOP=1 < $CURRENT_SQL_FILE 2> ${PSQLRESFL}
log_last_error_and_exit

# Mark the transferred records as completed
log INFO "Mark sync_statuses for transferred records"
envsubst < $ATHENA_RESULTS_SQL_FILE > $CURRENT_SQL_FILE
PGOPTIONS=--search_path=$ZEUS_FPHS_DB_SCHEMA psql -d $AWS_DB -h $AWS_DB_HOST -U $AWS_DB_USER -v ON_ERROR_STOP=1 < $CURRENT_SQL_FILE 2> ${PSQLRESFL}
log_last_error_and_exit

# ----> Cleanup
cleanup
