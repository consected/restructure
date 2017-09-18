#!/bin/bash
#

# Make a directory to store the source code and cd to it
# Then download and run this script:
#   read -p 'openmed username:' omu;curl -su $omu "https://open.med.harvard.edu/svn/fphs-rails/branches/phase3-1/fphs-scripts/setup_dev.sh" > /tmp/setup_dev.sh;sh /tmp/setup_dev.sh

# Set the required ruby version. 
RUBYVER=2.4.1

# --- setup_dev.sh prerequisites ---
# postgres 9.4 and postgres client
# svn client
# git client
clear
type pg_dump >/dev/null 2>&1 || { echo >&2 "I require pg_dump but it's not installed.  Aborting."; exit 1; }
type svn >/dev/null 2>&1 || { echo >&2 "I require svn client but it's not installed.  Aborting."; exit 1; }
type git >/dev/null 2>&1 || { echo >&2 "I require git client but it's not installed.  Aborting."; exit 1; }

echo "About to start setting up the environment. Are you in the directory you want to checkout to? "
echo `pwd`
echo Ctrl-C to exit, or return to contine
read GO

rtype=`type -P rvm`

if [ -n "$rtype" ]
then
  echo "rvm is installed. `ruby --version`"
  gr=`ruby --version |grep "ruby $RUBYVER"`
  if [ -z "$gr" ] 
  then 
    echo "RVM is installed. rvm install ruby $RUBYVER and set it as default, then rerun setup_dev.sh"
    exit 1
  fi
fi

rtype=`type -P rbenv`

if [ -n "$rtype" ]
then
  echo "rbenv is installed. `ruby --version`"
  gr=`ruby --version |grep "ruby $RUBYVER"`
  if [ -z "$gr" ] 
  then 
    echo Attempting to install ruby $RUBYVER and set it as default
    # Update rbenv, just in case it is needed to get the latest ruby version
    cd ~/.rbenv/plugins/ruby-build && git pull && cd -
    # Install the current Ruby version only if it is not already installed
    rbenv install -s $RUBYVER
    rbenv global $RUBYVER
    rbenv local $RUBYVER

    echo "Complete. Attempt to run setup_dev.sh again"
    exit 1
  fi
fi


echo Checking out the current HEAD to `pwd`. 
echo Enter your openmed username to contine:
read SVNUSR
svn checkout  --username="$SVNUSR" https://open.med.harvard.edu/svn/fphs-rails/branches/phase3-1 .


gem install bundler

bundle install

res=`psql -d fpa_development -c "select '1';"`
if [ -z "$res" ] 
then
echo "Enter sudo password to act as postgres to create database"
sudo -u postgres createdb -O `whoami` fpa_development
psql -d fpa_development  < ./db/dumps/development-data/data-dump.sql
else
echo "database fpa_development exists"
fi

res=`psql -d fpa_test -c "select '1';"`
if [ -z "$res" ] 
then
echo "Enter sudo password to act as postgres to create database"
sudo -u postgres createdb -O `whoami` fpa_test
psql -d fpa_test  < ./db/dumps/current_schema.sql
else
echo "database fpa_test exists"
fi

echo User `whoami` must be able to connect to Postgres as an OS user -- \'ident\' in pg_hba.conf

rake db:migrate
RAILS_ENV=test rake db:migrate
chmod 770 ./fphs-scripts/add_admin.sh
PWRES=`RAILS_ENV=development ./fphs-scripts/add_admin.sh admin@test.com`
clear
echo To run the app server run 
echo  bin/rails server
echo Then browse to http://localhost:3000/admins/sign_in
echo Login to server using credentials for $PWRES

