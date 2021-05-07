#!/usr/bin/env bash

NUM_WORKERS=${NUM_WORKERS:=1}

if [ ! -f '/opt/elasticbeanstalk/bin/get-config' ]; then
  echo "Didn't run restarter - not an AWS environment"
  exit
fi

if [ -z "${NUM_WORKERS}" ] || [ "${NUM_WORKERS}" == '0' ]; then
  echo "No workers requested"
  exit
fi

EB_SCRIPT_DIR=/opt/elasticbeanstalk/support/scripts
EB_SUPPORT_DIR=/opt/elasticbeanstalk/support
EB_APP_USER=webapp
EB_APP_CURRENT_DIR=/var/app/current
EB_APP_PIDS_DIR=/var/app/support/pids

if [ $(whoami) != "${EB_APP_USER}" ]; then
  echo "Must be run as ${EB_APP_USER}"
  exit 3
fi

# Setting up correct environment and ruby version so that bundle can load all gems
echo $EB_SUPPORT_DIR/envvars
. $EB_SUPPORT_DIR/envvars
. $EB_SCRIPT_DIR/use-app-ruby.sh

cd $EB_APP_CURRENT_DIR

source /etc/profile
# Provide a little time for delayed_job calling this to finish the job
sleep 2
bundle exec bin/delayed_job -n $NUM_WORKERS --pid-dir=$EB_APP_PIDS_DIR stop

sleeptime=20
for p in $(pgrep -u webapp -f delayed_job); do
  sleep $sleeptime
  sleeptime=0
  if [ $p != $$ ]; then
    kill $p 2> /dev/null
  fi
done
sleep 2

bundle exec bin/delayed_job -n $NUM_WORKERS --pid-dir=$EB_APP_PIDS_DIR start

echo 'Done'
