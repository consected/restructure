#!/bin/bash
# Get master record ID for the IPA subject
# Ensure credentials are set in file api_credentials.sh

if [ -z "${ipa_id}" ]
then
  cat <<EOF
Usage:
ipa_id=45754 \\
fphs-scripts/api_samples/get-container-id-from-filestore.sh

Change ipa_id to match the subject ID to search.
EOF
  exit
fi

cd $(dirname $0)
source ./api_credentials.sh
source ./supporting_fns.sh

call_res="$(curl --fail -sS "${api_server}/reports/${get_master_report_id}.csv?search_attrs%5Bipa_id%5D=${ipa_id}&use_app_type=${app_type}&user_email=${api_username}&user_token=${api_user_token}")"

if [ ! $? -eq 0 ]
then
  echo "Request failed"
  exit 1
fi

if [ "$(echo "${call_res}"| wc -l)" -eq 2 ]
then
  parse_master "${call_res}"
  echo ${master_id}
  exit 0
else
  echo "No container found"
  exit 1
fi

exit 1
