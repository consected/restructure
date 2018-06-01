#! /bin/bash
#
# This script is run periodically to synchronize new IPA records, requested in Elaine AWS DB
# pulling matching IPA IDs and associated player_infos and player_contacts from Zeus FPHS DB
# and pushing this data to Elaine AWS DB
#
# NOTE: master_id on Zeus FPHS DB and Elaine AWS DB ** do not match **.
#       Only IPA ID can be used to match records in Zeus and Elaine
#
# Cron is setup to run on the VNC server.
# In file /etc/cron.d/fphs_sync:
# MAILTO=""
# PATH=/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/aws/bin:/root/bin
# * * * * * fphsetl cd /<location of this file> ; RAILS_ENV=production EBENV=PROD-fphs ./sync_subject_data.sh > /dev/null 2>&1
#
# Ensure that .pgpass is setup with the appropriate credentials
#

WORKINGDIR=/tmp

cd $(dirname $0)

. ../sync_db_connections.sh

if [ -z "$ZEUS_DB" ]
then
  echo "No matching environment"
  exit 1
fi

# Main SQL scripts
IPA_ZEUS_FPHS_SQL_FILE=run_sync_subject_data_fphs_db.sql
IPA_AWS_SQL_FILE=run_sync_subject_data_aws_db.sql

# Temp files - can be anywhere - and will be cleaned up before and after use
IPA_SQL_FILE=$WORKINGDIR/temp_ipa.sql
IPA_IDS_FILE=$WORKINGDIR/remote_ipa_ids
IPA_ASSIGNMENTS_FILE=$WORKINGDIR/zeus_ipa_assignments.csv
IPA_PLAYER_INFOS_FILE=$WORKINGDIR/zeus_ipa_player_infos.csv
IPA_PLAYER_CONTACTS_FILE=$WORKINGDIR/zeus_ipa_player_contacts.csv

# Initially set the default schema for psql to be the AWS schema. This way, we do not need
# set search_path=... directly coded in the scripts
export PGOPTIONS=--search_path=$AWS_DB_SCHEMA

function cleanup {
  echo "Cleanup"
  rm $IPA_IDS_FILE
  rm $IPA_SQL_FILE
  rm $IPA_ASSIGNMENTS_FILE
  rm $IPA_PLAYER_INFOS_FILE
  rm $IPA_PLAYER_CONTACTS_FILE
}

# ----> Cleanup from previous runs, just in case
cleanup

# ----> On Remote AWS DB
# Run find_new_remote_ipa_records() and copy to a CSV file (IPA_IDS_FILE)
# This returns a list of IPA IDs to be sync'd from the Zeus FPHS DB
#
echo "Find remote IPA records"
echo "\copy (select * from find_new_remote_ipa_records()) to $IPA_IDS_FILE with (format csv, header true);" > $IPA_SQL_FILE
psql -d $AWS_DB -h $AWS_DB_HOST -U $AWS_DB_USER < $IPA_SQL_FILE


# ----> On Zeus FPHS DB
# Create a temp table temp_ipa_assignments to contain the IPA_IDS_FILE list of IPA IDs to sync
# Copy the IPA_IDS_FILE to temp_ipa_assignments
#
# For each temp_ipa_assignments record, update the record to include the Zeus master_id from the
# permanent ipa_assignments table
#
# For all master_id in temp_ipa_assignments table, copy matching player_infos and player_contacts records
# to CSV fields IPA_PLAYER_INFOS_FILE and IPA_PLAYER_CONTACTS_FILE
#
# Copy temp_ipa_assignments to IPA_ASSIGNMENTS_FILE

echo "Match and export Zeus records"
PGOPTIONS=--search_path=$ZEUS_FPHS_DB_SCHEMA psql -d $ZEUS_DB -h $ZEUS_FPHS_DB_HOST -U $ZEUS_FPHS_DB_USER < $IPA_ZEUS_FPHS_SQL_FILE

# ----> On Remote AWS DB
# Create temp tables for ipa_assignments, player_infos and player_contacts:
# temp_ipa_assignments, temp_player_infos and temp_player_contacts
#
# Copy IPA_IDS_FILE CSV data to temp_ipa_assignments
# Copy IPA_PLAYER_INFOS_FILE CSV data to temp_player_infos
# Copy IPA_PLAYER_CONTACTS_FILE CSV data to temp_player_contacts
# Copy IPA_ADDRESSES_FILE CSV data to temp_addresses
#
# Run create_all_remote_ipa_records() to scan the temp_ipa_assignments list of IPA records, and for each
# to select the matching temp_player_infos and temp_player_contacts records
# (matched on Zeus master_id, since the temp_* tables still reference temp_ipa_assignments through Zeus master_id).
#
# Now for each IPA ID record call create_remote_ipa_record(match_ipa_id, new_player_info_record, new_player_contact_records)
# This creates the player_infos, player_contacts and updates activity_log_ipa_assignments, using the
# AWS DB master_id and user_id as a substitution for the original values pulled from Zeus.
#

echo "Transfer matched records to remote DB"
psql -d $AWS_DB -h $AWS_DB_HOST -U $AWS_DB_USER < $IPA_AWS_SQL_FILE

# ----> Cleanup
cleanup
