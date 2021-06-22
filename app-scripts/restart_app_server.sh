#!/usr/bin/env bash

sleep 2

if [ ! -f '/opt/elasticbeanstalk/bin/get-config' ]; then
  touch /tmp/restart.txt
  exit 'Done'
fi

# This relies on the app server being set up as a systemd service, which will be restarted automatically.
# The AWS Elastic Beanstalk *Procfile* defines this service as 'web'.
kill --signal 15 -f $PPID

echo 'Done'
