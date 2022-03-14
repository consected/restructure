#!/usr/bin/env bash

sleep 2

if [ ! -f '/opt/elasticbeanstalk/bin/get-config' ]; then
  touch tmp/restart.txt
  echo 'Done'
  exit 0
fi

# This relies on the app server being set up as a systemd service, which will be restarted automatically.
# The AWS Elastic Beanstalk *Procfile* defines this service as 'web'.
# Also, the user running the application server needs to be in the sudoers file, to allow the service
# to be restarted. Set it up as root, with:

# cat > /etc/sudoers.d/webapp << SUDO
# webapp ALL= NOPASSWD: /bin/systemctl restart web.service
# webapp ALL= NOPASSWD: /bin/systemctl restart delayed_job.service
# SUDO

sudo /bin/systemctl restart web.service

echo 'Done'
