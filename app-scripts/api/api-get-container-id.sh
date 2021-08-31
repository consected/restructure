#!/bin/bash

if [ -z "${master_id}" ]; then
  cat << EOF
Usage:
upload_server="https://server.tld" \\
upload_user_email=sync_service_file_upload_client@server.tld \\
upload_user_token=<reset password to get a new token> \\
upload_app_type=6 \\
master_id=105190 \\
al_type=player_contact_phones \\
app-scripts/api/api-get-container-id.sh

Set DEBUG environment variable to any value to get full debug messages and JSON results
EOF
  exit
fi

if [ "$DEBUG" ]; then
  echo "Getting activities for master #{master_id}"
fi

activities="$(curl -s "${upload_server}/masters/${master_id}/activity_log/${al_type}.json?use_app_type=${upload_app_type}&user_email=${upload_user_email}&user_token=${upload_user_token}")"

if [ "$DEBUG" ]; then
  echo ${activities}
  echo
fi
echo ${activities} | jq -r ".activity_log__player_contact_phones[] | select(.extra_log_type == \"files\") | .model_references[] | select(.to_record_type_us == \"nfs_store__manage__container\").to_record_id " | head -n 1
