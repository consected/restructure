#!/usr/bin/env bash

NUM_WORKERS=${NUM_WORKERS:=1}

if [ ! -f '/opt/elasticbeanstalk/bin/get-config' ]; then
  echo "Didn't run restarter - not an AWS environment"
  exit
fi

sleep 2
# Also, the user running the application server needs to be in the sudoers file, to allow the service
# to be restarted. Set it up as root, with:

# cat > /etc/sudoers.d/webapp << SUDO
# webapp ALL= NOPASSWD: /bin/systemctl restart web.service
# webapp ALL= NOPASSWD: /bin/systemctl restart delayed_job.service
# webapp ALL= NOPASSWD: /bin/systemctl restart memcached.service
# SUDO

sudo /bin/systemctl restart memcached.service

echo 'Done'
