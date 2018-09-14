#!/bin/bash

if [ -z "${container_id}" ]
then
  cat <<EOF
Usage:
upload_server="https://file-upload-dev.32vnp6pmmu.us-east-1.elasticbeanstalk.com" \\
upload_user_email=sync_service_file_upload_client@app.fphs2.harvard.edu \\
upload_user_token=<reset password to get a new token> \\
upload_app_type=3 \\
upload_filename=123457_persnet.pdf \\
upload_file=/home/phil/Downloads/123457_persnet.pdf \\
container_id=27 \\
fphs-scripts/upload-to-filestore.sh
EOF
  exit
fi

upload_md5=$(md5sum "${upload_file}" | awk '{print $1}')

echo "Checking file ${upload_filename} with MD5 hash ${upload_md5}"

upload_test="$(curl "${upload_server}/nfs_store/chunk/${container_id}.json?use_app_type=${upload_app_type}&user_email=${upload_user_email}&user_token=${upload_user_token}&file_name=${upload_filename}&file_hash=${upload_md5}")"

if [ ! -z "$(echo ${upload_test} | grep '"result":"not found"')" ]
then
  echo "Uploading file ${upload_file}"

  curl "${upload_server}/nfs_store/chunk.json?user_email=${upload_user_email}&user_token=${upload_user_token}" \
  -F "file_hash=${upload_md5}" \
  -F "container_id=${container_id}" \
  -F "chunk_hash=${upload_md5}" \
  -F "upload=@${upload_file}" \
  --compressed

else
  echo "This file already exist in the chosen container: ${upload_file}"
fi
