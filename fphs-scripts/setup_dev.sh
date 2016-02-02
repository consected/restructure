#!/bin/bash

echo Checking out the current HEAD to `pwd`
svn checkout https://open.med.harvard.edu/svn/fphs-rails/branches/phase3-1 .

# Update rbenv, just in case it is needed to get the latest ruby version
cd ~/.rbenv/plugins/ruby-build && git pull && cd -

# Install the current Ruby version only if it is not already installed
rbenv install -s 2.2.4


echo "Enter sudo password to act as postgres to create database"

sudo -u postgres createdb -O `whoami` fpa_development
sudo -u postgres createdb -O `whoami` fpa_test
psql -d fpa_development  < ./db/dumps/development-data/data-dump.sql
psql -d fpa_test  < ./db/dumps/development-data/data-dump.sql

echo User `whoami` must be able to connect to Postgres as an OS user (\'ident\' in pg_hba.conf)

rake db: migrate
RAILS_ENV=test rake db: migrate



