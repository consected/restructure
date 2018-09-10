#! /bin/bash
#
# This script is run periodically to synchronize new {{app_name_uc}} records, requested in Elaine AWS DB
# pulling matching {{app_name_uc}} IDs and associated player_infos and player_contacts from Zeus FPHS DB
# and pushing this data to Elaine AWS DB
#
# NOTE: master_id on Zeus FPHS DB and Elaine AWS DB ** do not match **.
#       Only {{app_name_uc}} ID can be used to match records in Zeus and Elaine
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
{{app_name_uc}}_ZEUS_FPHS_SQL_FILE=run_sync_subject_data_fphs_db.sql
{{app_name_uc}}_AWS_SQL_FILE=run_sync_subject_data_aws_db.sql

# Temp files - can be anywhere - and will be cleaned up before and after use
{{app_name_uc}}_SQL_FILE=$WORKINGDIR/temp_{{app_name}}.sql
{{app_name_uc}}_IDS_FILE=$WORKINGDIR/remote_{{app_name}}_ids
{{app_name_uc}}_ASSIGNMENTS_FILE=$WORKINGDIR/zeus_{{app_name}}_assignments.csv
{{app_name_uc}}_PLAYER_INFOS_FILE=$WORKINGDIR/zeus_{{app_name}}_player_infos.csv
{{app_name_uc}}_PLAYER_CONTACTS_FILE=$WORKINGDIR/zeus_{{app_name}}_player_contacts.csv

# Initially set the default schema for psql to be the AWS schema. This way, we do not need
# set search_path=... directly coded in the scripts
export PGOPTIONS=--search_path=$AWS_DB_SCHEMA

function cleanup {
  echo "Cleanup"
  rm ${{app_name_uc}}_IDS_FILE
  rm ${{app_name_uc}}_SQL_FILE
  rm ${{app_name_uc}}_ASSIGNMENTS_FILE
  rm ${{app_name_uc}}_PLAYER_INFOS_FILE
  rm ${{app_name_uc}}_PLAYER_CONTACTS_FILE
}

# ----> Cleanup from previous runs, just in case
cleanup

# ----> On Remote AWS DB
# Run find_new_remote_{{app_name}}_records() and copy to a CSV file ({{app_name_uc}}_IDS_FILE)
# This returns a list of {{app_name_uc}} IDs to be sync'd from the Zeus FPHS DB
#
echo "Find remote {{app_name_uc}} records"
echo "\copy (select * from find_new_remote_{{app_name}}_records()) to ${{app_name_uc}}_IDS_FILE with (format csv, header true);" > ${{app_name_uc}}_SQL_FILE
psql -d $AWS_DB -h $AWS_DB_HOST -U $AWS_DB_USER < ${{app_name_uc}}_SQL_FILE


# ----> On Zeus FPHS DB
# Create a temp table temp_{{app_name}}_assignments to contain the {{app_name_uc}}_IDS_FILE list of {{app_name_uc}} IDs to sync
# Copy the {{app_name_uc}}_IDS_FILE to temp_{{app_name}}_assignments
#
# For each temp_{{app_name}}_assignments record, update the record to include the Zeus master_id from the
# permanent {{app_name}}_assignments table
#
# For all master_id in temp_{{app_name}}_assignments table, copy matching player_infos and player_contacts records
# to CSV fields {{app_name_uc}}_PLAYER_INFOS_FILE and {{app_name_uc}}_PLAYER_CONTACTS_FILE
#
# Copy temp_{{app_name}}_assignments to {{app_name_uc}}_ASSIGNMENTS_FILE

echo "Match and export Zeus records"
PGOPTIONS=--search_path=$ZEUS_FPHS_DB_SCHEMA psql -d $ZEUS_DB -h $ZEUS_FPHS_DB_HOST -U $ZEUS_FPHS_DB_USER < ${{app_name_uc}}_ZEUS_FPHS_SQL_FILE

# ----> On Remote AWS DB
# Create temp tables for {{app_name}}_assignments, player_infos and player_contacts:
# temp_{{app_name}}_assignments, temp_player_infos and temp_player_contacts
#
# Copy {{app_name_uc}}_IDS_FILE CSV data to temp_{{app_name}}_assignments
# Copy {{app_name_uc}}_PLAYER_INFOS_FILE CSV data to temp_player_infos
# Copy {{app_name_uc}}_PLAYER_CONTACTS_FILE CSV data to temp_player_contacts
#
# Run create_all_remote_{{app_name}}_records() to scan the temp_{{app_name}}_assignments list of {{app_name_uc}} records, and for each
# to select the matching temp_player_infos and temp_player_contacts records
# (matched on Zeus master_id, since the temp_* tables still reference temp_{{app_name}}_assignments through Zeus master_id).
#
# Now for each {{app_name_uc}} ID record call create_remote_{{app_name}}_record(match_{{app_name}}_id, new_player_info_record, new_player_contact_records)
# This creates the player_infos, player_contacts and updates activity_log_{{app_name}}_assignments, using the
# AWS DB master_id and user_id as a substitution for the original values pulled from Zeus.
#

echo "Transfer matched records to remote DB"
psql -d $AWS_DB -h $AWS_DB_HOST -U $AWS_DB_USER < ${{app_name_uc}}_AWS_SQL_FILE

# ----> Cleanup
cleanup
