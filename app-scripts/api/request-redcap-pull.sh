#!/bin/bash

if [ -z "${redcap_project}" ]; then
  cat << EOF
Usage:
app_server="https://server.tld" \\
app_user_email=redcap_det@local \\
app_user_token=<reset password to get a new token> \\
app_type=63 \\
redcap_project='<id, project name or instrument name>' \\
app-scripts/api/request-redcap-pull.sh

Set DEBUG environment variable to any value to get full debug messages and JSON results
EOF
  exit
fi

if [ "$DEBUG" ]; then
  echo "Getting redcap pull request results"
fi

results="$(curl -XPOST "${app_server}/redcap/project_user_requests/${redcap_project}/request_records.json?use_app_type=${app_type}&user_email=${app_user_email}&user_token=${app_user_token}")"

if [ "$DEBUG" ]; then
  echo ${results}
  echo
fi
