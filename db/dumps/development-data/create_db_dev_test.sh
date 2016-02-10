#!/bin/bash

#### This script is used by fphs_scripts/setup_dev.sh
#
# Note: the database dump was created with
#   sudo -u postgres pg_dump -d fpa_development -O -n ml_app > ./db/dumps/development-data/data-dump.sql
#
echo "Enter sudo password to act as postgres to create database"

sudo -u postgres createdb -O `whoami` fpa_development
sudo -u postgres createdb -O `whoami` fpa_test
psql -d fpa_development  < ./db/dumps/development-data/data-dump.sql
psql -d fpa_test  < ./db/dumps/current_schema.sql
