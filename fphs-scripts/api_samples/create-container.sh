#!/bin/bash
# IPA Files script for creating an assessment files container
# Ensure credentials are set in file api_credentials.sh

if [ -z "${ipa_id}" ]
then
  cat <<EOF
Usage:
ipa_id=999999990 \
session_type=mri \\
notes="This is a test" \\
fphs-scripts/upload-to-filestore.sh

The result should be a JSON string starting with:

  {"activity_log__ipa_assignment_session_filestore":{

This represents success for the container creation.

EOF
  exit 1
fi

cd $(dirname $0)
source ./api_credentials.sh
source ./supporting_fns.sh

container_res=$(./get-container-from-filestore.sh)

container_exists "${container_res}"

if [ $? -eq 0 ]
then

  master_id=$(./get-master-for-ipa-id.sh)

  if [ ! $? -eq 0 ]
  then
    echo "Request failed"
    exit 1
  fi

  echo "Creating container for ${master_id}"

  curl "${api_server}/masters/${master_id}/activity_log/ipa_assignment_session_filestores.json?extra_type=${session_type}&user_email=${api_username}&user_token=${api_user_token}" \
  -F "activity_log_ipa_assignment_session_filestore[extra_log_type]=${session_type}" \
  -F "activity_log_ipa_assignment_session_filestore[select_status]=open" \
  -F "activity_log_ipa_assignment_session_filestore[notes]=${notes}"

else

  echo "Container already exists"
  exit 1

fi
