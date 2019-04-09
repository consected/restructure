#!/bin/bash
# All in one script to find the details for a container based on subject ID and container type,
# then upload a file from the filesystem to this container
# Ensure credentials are set in file api_credentials.sh

if [ -z "${ipa_id}" ]
then
  cat <<EOF

Usage:
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

cd $(dirname $0)
source ./api_credentials.sh
source ./supporting_fns.sh

container_res=$(./get-container-from-filestore.sh)

parse_container_res "${container_res}"

./upload-to-filestore.sh
