Sync Process
==

This directory contains shared and app specific scripts for the synchronization of data from
the Zeus FPHS/ML_APP database, to the Elaine DB on AWS.

Directory structure
--

- sync-process/**sync_db_connections.sh**

  File sourced by the app-specific sync scripts. Contains non-private connection information for the database.

- sync-process/**bhs-sync**/*

  BHS (Elaine) sync scripts


The details for each app appear below.

BHS (Elaine) Sync
==

The script `sync_subject_data.sh` is run periodically to synchronize new BHS records requested in Elaine AWS DB,
pulling matching BHS IDs and associated player_infos and player_contacts from Zeus FPHS DB
and pushing this data to Elaine AWS DB

Master IDs
--

*NOTE:* master_id on Zeus FPHS DB and Elaine AWS DB **do not match**.

  Only BHS ID can be used to match records in Zeus and Elaine

Files
--

sync-process/**bhs-sync**
- **run_sync_subject_data_aws_db.sql**

  SQL to copy the sync data to the Elaine AWS database

- **run_sync_subject_data_fphs_db.sql**

  SQL to retrieve data from the Zeus FPHS ml_app database for sync to Elaine

- **sync_subject_data.sh**

  Bash script to control the sync process, run periodically from a cron job

Notes about the SQL scripts
--
The SQL scripts contain `\copy` psql statements to handle the simplified copying of data into and out of escaped CSV files for moving data between environments without requiring text manipulation. These standalone SQL files have been used, rather than DB stored procedures, since the regular SQL `copy` statement requires superuser access while `\copy` works safely with a regular user. Once this copying has been complete, a final function `create_all_remote_bhs_records()` is called on the AWS database to complete the logic for the transfer.

Cron setup
--

Cron will be setup to run on the VNC server. In file **/etc/cron.d/fphs_sync**:

    MAILTO=""
    PATH=/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/aws/bin:/root/bin
    * * * * * fphsetl cd /<location of this file> ; RAILS_ENV=production EBENV=PROD-fphs ./sync_subject_data.sh > /dev/null 2>&1


.pgpass for credentials
--

Ensure that **.pgpass** for user **fphsetl** is setup with the appropriate credentials for both FPHS and AWS databases.

Testing
--

Run the following to test the database connections.

    RAILS_ENV=production EBENV=PROD-fphs sync-process/bhs-sync/sync_subject_data.sh
