#!/bin/bash

if [ -z "${master_id}" ]
then
  cat <<EOF
Usage:
upload_server="https://appdev.fphs2.harvard.edu" \\
upload_user_email=sync_service_file_upload_client@app.fphs2.harvard.edu \\
upload_user_token=<reset password to get a new token> \\
upload_app_type=6 \\
master_id=105190 \\
al_type=persnet_assignments \\
fphs-scripts/upload-to-filestore.sh
EOF
  exit
fi

echo "Getting activities for master #{master_id}"

activities="$(curl "${upload_server}/masters/${master_id}/activity_log/${al_type}?use_app_type=${upload_app_type}&user_email=${upload_user_email}&user_token=${upload_user_token}")"

echo ${activities} | jq -r ".activity_log__persnet_assignments[] | select(.extra_log_type == \"primary\") | .model_references[] | select(.to_record_type_us == \"nfs_store__manage__container\").to_record_id " | head -n 1
