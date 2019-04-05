#!/bin/bash
# All in one script to find the details for a container based on subject ID and container type,
# then upload a file from the filesystem to this container

if [ -z "${ipa_id}" ]
then
  cat <<EOF

Usage:
upload_server="https://file-upload-dev.32vnp6pmmu.us-east-1.elasticbeanstalk.com" \\
upload_user_email=api_file_upload_client@app.fphs2.harvard.edu \\
upload_user_token=<reset password to get a new token> \\
upload_app_type=3 \\
upload_filename=123457_persnet.pdf \\
upload_file=/home/phil/Downloads/123457_persnet.pdf \\
ipa_id=45754 \\
session_type=mri \\
fphs-scripts/upload-to-filestore.sh

Variables:
ipa_id - the subject ID to upload to
upload_file - full path to the file to upload
upload_filename - the filename to show to end users

EOF
  exit 1
fi

# Report number that returns container details for a subject and session type
export report_id=13

cd $(dirname $0)
export container_res=$(./get-container-from-filestore.sh)

if [ "${container_res}" == "Request failed" ] || [ "${container_res}" == "No container found" ]
then
  echo "Container request failed"
  exit 1
else
  echo "Uploading to container: ${container_res}"
fi


IFS=','
read -ra ADDR <<< "${container_res}"
export container_id="${ADDR[0]}"
export activity_log_id="${ADDR[1]}"
export activity_log_type="${ADDR[2]}"

./upload-to-filestore.sh
