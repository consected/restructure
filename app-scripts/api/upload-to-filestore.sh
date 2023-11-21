#!/bin/bash

if [ -z "${container_id}" ] || [ -z "${upload_file}" ] || [ -z "${upload_filename}" ]; then
  cat >&2 << EOF
Usage:
upload_server="https://file-upload-dev.32vnp6pmmu.us-east-1.elasticbeanstalk.com" \\
upload_user_email=sync_service_file_upload_client@server.tld \\
upload_user_token=<reset password to get a new token> \\
upload_app_type=3 \\
upload_filename=123457_persnet.pdf \\
upload_file=~/Downloads/123457_persnet.pdf \\
container_id=75 \\
activity_log_id=73 \\
activity_log_type=activity_log__ipa_assignment_session_filestore \\
app-scripts/api/upload-to-filestore.sh
EOF
  exit 100
fi

if [ ! -f "${upload_file}" ]; then
  echo -e "\e[31mError:\e[0m File upload_file does not exist: ${upload_file}" >&2
  exit 101
fi

upload_md5=$(md5sum "${upload_file}" | awk '{print $1}')
res=$?
if [ ${res} != 0 ] || [ ! "${upload_md5}" ]; then
  echo -e "\e[31mError ${res}:\e[0m Failed to calculate MD5 hash for file '${upload_file}'" >&2
  echo "Check md5sum and awk are installed" >&2
  exit 114
fi

# echo "Checking file ${upload_filename} with MD5 hash ${upload_md5}"
upload_test="$(curl ${curl_args} "${upload_server}/nfs_store/chunk/${container_id}.json?activity_log_id=${activity_log_id}&activity_log_type=${activity_log_type}&use_app_type=${upload_app_type}&user_email=${upload_user_email}&user_token=${upload_user_token}&file_name=${upload_filename}&file_hash=${upload_md5}")"

res=$?
if [ ${res} != 0 ]; then
  echo -e "\e[31mError ${res}:\e[0m Failed to check file" >&2
  echo "${upload_test}" >&2
  exit 111
fi

if [ "$(echo ${upload_test} | grep '"message":"The filters do not allow upload of this file')" ]; then
  echo -e "\e[31mError:\e[0m The filters do not allow upload of this file"
  echo "${upload_test}" >&2
  exit 113
fi

if [ "$(echo ${upload_test} | grep '"result":"not found"')" ]; then
  echo "Uploading file ${upload_file}"

  upload_res=$(curl ${curl_args} "${upload_server}/nfs_store/chunk.json?user_email=${upload_user_email}&user_token=${upload_user_token}" \
    -F "upload_set=${upload_md5}" \
    -F "file_hash=${upload_md5}" \
    -F "container_id=${container_id}" \
    -F "activity_log_id=${activity_log_id}" \
    -F "activity_log_type=${activity_log_type}" \
    -F "chunk_hash=${upload_md5}" \
    -F "upload=@${upload_file}" \
    --compressed)

  res=$?
  if [ ${res} == 0 ]; then
    echo "Uploaded file successfully ${upload_file}"
    exit 0
  else
    echo -e "\e[31mError ${res}:\e[0m Failed to upload file" >&2
    exit 110
  fi

else
  echo -e "\e[31mError:\e[0m This file already exist in container ${container_id}: ${upload_file}" >&2
  echo "${upload_test}" >&2
  exit 102
fi
