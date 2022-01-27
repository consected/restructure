#!/usr/bin/env bash

sleep 2

if [ ! -f '/opt/elasticbeanstalk/bin/get-config' ]; then
  export AWS_DEFAULT_REGION=$(curl http://169.254.169.254/latest/dynamic/instance-identity/document --silent | grep region | awk -F\" '{print $4}')
  export AWS_REGION=${AWS_DEFAULT_REGION}
  INSTID=$(ec2-metadata -i | awk '{print $2}')
  EBID=$(aws ec2 describe-tags --filter "Name=resource-id,Values=${INSTID}" --query 'Tags[?Key==`elasticbeanstalk:environment-id`].Value' --output text)
  if [ "${EBID}" ]; then
    aws elasticbeanstalk restart-app-server --environment-id ${EBID}
  else
    touch tmp/restart.txt
  fi
  exit 'Done'
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
