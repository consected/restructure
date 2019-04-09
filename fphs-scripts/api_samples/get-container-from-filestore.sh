#!/bin/bash
# Get the container details for an IPA subject, used to upload files in the upload-to-filestore.sh script
# Ensure credentials are set in file api_credentials.sh

if [ -z "${ipa_id}" ]
then
  cat <<EOF
Usage:
session_type=mri \\
ipa_id=45754 \\
fphs-scripts/api_samples/get-container-id-from-filestore.sh

Change ipa_id to match the subject ID to upload to.
EOF
  exit
fi

cd $(dirname $0)
source ./api_credentials.sh
source ./supporting_fns.sh

container_res="$(curl --fail -sS "${api_server}/reports/${get_container_report_id}.csv?search_attrs%5Bipa_id%5D=${ipa_id}&search_attrs%5Bsession_type%5D=${session_type}&use_app_type=${app_type}&user_email=${api_username}&user_token=${api_user_token}")"

if [ ! $? -eq 0 ]
then
  echo "Request failed"
  exit 1
fi

if [ "$(echo "${container_res}"| wc -l)" -gt 1 ]
then
  echo "${container_res}" | tail -n 1
  exit 0
else
  echo "No container found"
  exit 1
fi
