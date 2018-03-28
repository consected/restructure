#! /bin/bash
#
# This script is run periodically to synchronize new BHS records, requested in Elaine AWS DB
# pulling matching BHS IDs and associated player_infos and player_contacts from Zeus FPHS DB
# and pushing this data to Elaine AWS DB
#
# NOTE: master_id on Zeus FPHS DB and Elaine AWS DB ** do not match **.
#       Only BHS ID can be used to match records in Zeus and Elaine

export AWS_DB=fphs
export ZEUS_DB=fphs

export ZEUS_FPHS_DB_SCHEMA=ml_app2
export ZEUS_FPHS_DB_HOST=
export ZEUS_FPHS_DB_USER=fphs
export AWS_DB_SCHEMA=ml_app
export AWS_DB_HOST=
export AWS_DB_USER=fphs

export PGOPTIONS=--search_path=$AWS_DB_SCHEMA
export BHS_SQL_FILE=/tmp/temp_bhs.sql
export BHS_ZEUS_FPHS_SQL_FILE=./db/app_specific/bhs/run_sync_subject_data_fphs_db.sql
export BHS_AWS_SQL_FILE=./db/app_specific/bhs/run_sync_subject_data_aws_db.sql
export BHS_IDS_FILE=/tmp/remote_bhs_ids
export BHS_ASSIGNMENTS_FILE=/tmp/zeus_bhs_assignments.csv
export BHS_PLAYER_INFOS_FILE=/tmp/zeus_bhs_player_infos.csv
export BHS_PLAYER_CONTACTS_FILE=/tmp/zeus_bhs_player_contacts.csv

# ----> Cleanup from previous runs, just in case
rm $BHS_IDS_FILE
rm $BHS_SQL_FILE

# ----> On Remote AWS DB
# Run find_new_remote_bhs_record() and copy to a CSV file (BHS_IDS_FILE)
# This returns a list of BHS IDs to be sync'd from the Zeus FPHS DB
#
echo "\copy (select * from find_new_remote_bhs_records()) to $BHS_IDS_FILE with (format csv, header true);" > $BHS_SQL_FILE
psql -d $AWS_DB -h $AWS_DB_HOST -U $AWS_DB_USER < $BHS_SQL_FILE


# ----> On Zeus FPHS DB
# Create a temp table temp_bhs_assignments to contain the BHS_IDS_FILE list of BHS IDs to sync
# Copy the BHS_IDS_FILE to temp_bhs_assignments
#
# For each temp_bhs_assignments record, update the record to include the Zeus master_id from the
# permanent bhs_assignments table
#
# For all master_id in temp_bhs_assignments table, copy matching player_infos and player_contacts records
# to CSV fields BHS_PLAYER_INFOS_FILE and BHS_PLAYER_CONTACTS_FILE
#
# Copy temp_bhs_assignments to BHS_ASSIGNMENTS_FILE

PGOPTIONS=--search_path=$ZEUS_FPHS_DB_SCHEMA psql -d $ZEUS_DB -h $ZEUS_FPHS_DB_HOST -U $ZEUS_FPHS_DB_USER < $BHS_ZEUS_FPHS_SQL_FILE

# ----> On Remote AWS DB
# Create temp tables for bhs_assignments, player_infos and player_contacts:
# temp_bhs_assignments, temp_player_infos and temp_player_contacts
#
# Copy BHS_IDS_FILE CSV data to temp_bhs_assignments
# Copy BHS_PLAYER_INFOS_FILE CSV data to temp_player_infos
# Copy BHS_PLAYER_CONTACTS_FILE CSV data to temp_player_contacts
#
# Run create_all_remote_bhs_records() to scan the temp_bhs_assignments list of BHS records, and for each
# to select the matching temp_player_infos and temp_player_contacts records
# (matched on Zeus master_id, since the temp_* tables still reference temp_bhs_assignments through Zeus master_id).
#
# Now for each BHS ID record call create_remote_bhs_record(match_bhs_id, new_player_info_record, new_player_contact_records)
# This creates the player_infos, player_contacts and updates activity_log_bhs_assignments, using the
# AWS DB master_id and user_id as a substitution for the original values pulled from Zeus.
#
psql -d $AWS_DB -h $AWS_DB_HOST -U $AWS_DB_USER < $BHS_AWS_SQL_FILE
