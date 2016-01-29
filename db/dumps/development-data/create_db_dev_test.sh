#!/bin/bash
echo "Enter sudo password to act as postgres to create database"

sudo -u postgres createdb -O `whoami` fpa_development
sudo -u postgres createdb -O `whoami` fpa_test
psql -d fpa_development  < ./db/dumps/development-data/data-dump.sql
psql -d fpa_test  < ./db/dumps/development-data/data-dump.sql
