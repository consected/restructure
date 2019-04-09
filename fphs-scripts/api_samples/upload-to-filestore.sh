#!/bin/bash
# General purpose script for uploading to the filestore if you know the container ID to be uploaded to
# Ensure credentials are set in file api_credentials.sh

if [ -z "${container_id}" ] || [ -z "${upload_file}" ]
then
  cat <<EOF
Usage:
upload_filename=123457_persnet.pdf \\
upload_file=/home/phil/Downloads/123457_persnet.pdf \\
container_id=75 \\
activity_log_id=73 \\
activity_log_type=activity_log__ipa_assignment_session_filestore \\
fphs-scripts/upload-to-filestore.sh
EOF
  exit 1
fi

EXTRA_ARGS="--progress-bar --compressed"

cd $(dirname $0)
source ./api_credentials.sh
source ./supporting_fns.sh

if [ ! -f "${upload_file}" ]
then
  echo "File upload_file does not exist: ${upload_file}"
  exit 1
fi

upload_md5=$(md5sum "${upload_file}" | awk '{print $1}')

echo "Checking file ${upload_filename} with MD5 hash ${upload_md5}"
upload_test="$(curl -sS "${api_server}/nfs_store/chunk/${container_id}.json?activity_log_id=${activity_log_id}&activity_log_type=${activity_log_type}&use_app_type=${app_type}&user_email=${api_username}&user_token=${api_user_token}&file_name=${upload_filename}&file_hash=${upload_md5}")"

if [ $? -eq 0 ] && [ ! -z "$(echo ${upload_test} | grep '"result":"not found"')" ]
then
  rm -f upload-result.txt
  echo "Uploading file ${upload_file}"
  echo "Started at $(date)"
  echo "Progress:"
  curl "${api_server}/nfs_store/chunk.json?user_email=${api_username}&user_token=${api_user_token}" \
  -F "file_hash=${upload_md5}" \
  -F "container_id=${container_id}" \
  -F "activity_log_id=${activity_log_id}" \
  -F "activity_log_type=${activity_log_type}" \
  -F "chunk_hash=${upload_md5}" \
  -F "upload=@${upload_file}" \
  ${EXTRA_ARGS} > upload-result.txt

  cat upload-result.txt
  echo ""
  echo "Ended at $(date)"
  exit 0
fi

if [ $? -eq 0 ] && [ ! -z "$(echo ${upload_test} | grep '"A matching stored file already exists"')" ]
then
  echo "${upload_test}"
  echo "This file already exist in container ${container_id}: ${upload_file}"
  exit 1
else
  echo "${upload_test}"
  echo "Could not get file upload test result"
  exit 1
fi
