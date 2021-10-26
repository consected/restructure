#!/bin/bash
#
# Clean up temp files and directories in production, plus restart to make sure nothing is missing
#
# Cron with something like this:
#
# MAILTO=""
# PATH=/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/aws/bin:/root/bin
# 0 3 * * * root /var/app/current/app-scripts/tempfile-cleanup.sh
#

AGE_MINS=240

find /tmp -name 'secure-view*' -mmin +${AGE_MINS} -exec rm -rf {} \;
find /tmp -name 'nfs-store*' -mmin +${AGE_MINS} -exec rm -rf {} \;
find /tmp/uploads -name '__filestore*' -mmin +${AGE_MINS} -exec rm -rf {} \;
find /tmp/uploads -name 'container*' -mmin +${AGE_MINS} -exec rm -rf {} \;
systemctl restart web
systemctl restart delayed_job
