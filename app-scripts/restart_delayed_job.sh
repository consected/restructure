#!/usr/bin/env bash

NUM_WORKERS=${NUM_WORKERS:=1}

if [ ! -f '/opt/elasticbeanstalk/bin/get-config' ]; then
  echo "Didn't run restarter - not an AWS environment"
  exit
fi

# This relies on delayed_job being set up as a systemd service, which will be restarted automatically.
# The AWS Elastic Beanstalk *Procfile* defines this service.
pkill --signal 15 -f bin/delayed_job

echo 'Done'
