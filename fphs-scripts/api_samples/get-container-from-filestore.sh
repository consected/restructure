#!/bin/bash

if [ -z "${ipa_id}" ]
then
  cat <<EOF
Usage:
upload_server="https://file-upload-dev.32vnp6pmmu.us-east-1.elasticbeanstalk.com" \\
upload_user_email=api_file_upload_client@app.fphs2.harvard.edu \\
upload_user_token=<reset password to get a new token> \\
upload_app_type=3 \\
report_id=13 \\
session_type=mri \\
ipa_id=45754 \\
fphs-scripts/api_samples/get-container-id-from-filestore.sh

Change ipa_id to match the subject ID to upload to.
EOF
  exit
fi
# echo "${upload_server}/reports/${report_id}.csv?search_attrs%5Bipa_id%5D=${ipa_id}&search_attrs%5Bsession_type%5D=${session_type}&use_app_type=${upload_app_type}&user_email=${upload_user_email}&user_token=${upload_user_token}"
container_res="$(curl --fail -s "${upload_server}/reports/${report_id}.csv?search_attrs%5Bipa_id%5D=${ipa_id}&search_attrs%5Bsession_type%5D=${session_type}&use_app_type=${upload_app_type}&user_email=${upload_user_email}&user_token=${upload_user_token}")"

if [ ! $? -eq 0 ]
then
  echo "Request failed"
  exit 1
fi

if [ "$(echo "${container_res}"| wc -l)" -eq 2 ]
then
  echo "${container_res}" | tail -n 1
  exit 0
else
  echo "No container found"
  exit 1
fi
