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

EB_SCRIPT_DIR=$(/opt/elasticbeanstalk/bin/get-config container -k script_dir)
EB_SUPPORT_DIR=$(/opt/elasticbeanstalk/bin/get-config container -k support_dir)
EB_APP_USER=$(/opt/elasticbeanstalk/bin/get-config container -k app_user)
EB_APP_CURRENT_DIR=$(/opt/elasticbeanstalk/bin/get-config container -k app_deploy_dir)
EB_APP_PIDS_DIR=$(/opt/elasticbeanstalk/bin/get-config container -k app_pid_dir)

if [ $(whoami) != "${EB_APP_USER}" ]; then
  echo "Must be run as ${EB_APP_USER}"
  exit 3
fi

# Setting up correct environment and ruby version so that bundle can load all gems
echo $EB_SUPPORT_DIR/envvars
. $EB_SUPPORT_DIR/envvars
. $EB_SCRIPT_DIR/use-app-ruby.sh

cd $EB_APP_CURRENT_DIR

bundle exec bin/delayed_job -n $NUM_WORKERS --pid-dir=$EB_APP_PIDS_DIR restart
