#!/bin/bash

if [ -z "${redcap_project}" ]; then
  cat << EOF
Usage:
app_server="https://server.tld" \\
app_user_email=redcap_det@local \\
app_user_token=<reset password to get a new token> \\
app_type=63 \\
id='<id, project name or "project_id">'
redcap_project='<redcap project_id>' \\
redcap_url='https://redcap.fphs.harvard.edu/api/' \\
app-scripts/api/request-redcap-pull.sh

Set DEBUG environment variable to any value to get full debug messages and JSON results
EOF
  exit
fi

url="${app_server}/redcap/project_user_requests/${id}/request_records.json?project_id=${redcap_project}&server_url=${redcap_url}&use_app_type=${app_type}&user_email=${app_user_email}&user_token=${app_user_token}"

if [ "$DEBUG" ]; then
  echo "Getting redcap pull request results"
  echo ${url}
fi

results="$(curl -XPOST ${url})"

if [ "$DEBUG" ]; then
  echo ${results}
  echo
fi
