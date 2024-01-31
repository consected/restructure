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
  echo -e "\e[31mcURL Error ${res}:\e[0m Failed to check file" >&2
  echo -e "\e[31mResponse:\e[0m ${upload_test}" >&2
  exit 111
fi

if [ "$(echo ${upload_test} | grep '"message":"The filters do not allow upload of this file')" ]; then
  echo -e "\e[31mError:\e[0m The filters do not allow upload of this file"
  echo -e "\e[31mResponse:\e[0m ${upload_test}" >&2
  exit 113
fi

if [ "$(echo ${upload_test} | grep '"result":"not found"')" ] || [ "$(echo ${upload_test} | grep '"result":"found","completed":false,"chunk_count":0')" ]; then
  echo "Splitting file"
  chunk_size_max=10000000
  splitdir="$(dirname "${upload_file}")"
  echo "${splitdir}"
  split_prefix="${splitdir}/fs-upload-split-file-"
  [ -z "${split_prefix}" ] || rm -f "${split_prefix}"*
  split --bytes=${chunk_size_max} --suffix-length=4 "${upload_file}" "${split_prefix}"

  file_size=$(stat -c %s "${upload_file}")
  echo "Uploading file ${upload_file} -- size ${file_size}"

  upload_set="${upload_md5}-$(date -Ins)"
  range_start=0

  for chunk_path in $(ls "${split_prefix}"*); do

    chunk_size=$(stat -c %s "${chunk_path}")
    chunk_md5=$(md5sum "${chunk_path}" | awk '{print $1}')
    range_end=$((${range_start} + ${chunk_size} - 1))
    content_range="bytes ${range_start}-${range_end}/${file_size}"
    range_start=$((${range_end} + 1))

    echo "Uploading file ${chunk_path} -- size ${chunk_size} -- ${content_range}"

    upload_res=$(
      curl ${curl_args} "${upload_server}/nfs_store/chunk.json?user_email=${upload_user_email}&user_token=${upload_user_token}" \
        -H "Content-Range: ${content_range}" \
        -F "upload_set=${upload_set}" \
        -F "file_hash=${upload_md5}" \
        -F "container_id=${container_id}" \
        -F "activity_log_id=${activity_log_id}" \
        -F "activity_log_type=${activity_log_type}" \
        -F "chunk_hash=${chunk_md5}" \
        -F "upload=@${chunk_path}; filename=${upload_filename}" \
        --compressed
    )

    res=$?
    echo "${upload_res}"

    if [ ${res} == 0 ]; then
      got_id=$(echo "${upload_res}" | jq -r ".file.id")

      if [ -z "${got_id}" ] || [ "${got_id}" == 'null' ]; then
        res=1
      else
        if [ -z "${uploaded_ids}" ]; then
          uploaded_ids="${got_id}"
        else
          uploaded_ids="${uploaded_ids},${got_id}"
        fi
        res=0
      fi
    fi

    if [ ${res} == 0 ]; then
      echo -e "\e[32mUploaded file chunk successfully:\e[0m ${chunk_path}"
      rm "${chunk_path}"
    else
      echo -e "\e[31mcURL Error ${res}:\e[0m Failed to upload file" >&2
      [ -z "${split_prefix}" ] || rm -f "${split_prefix}"*
      exit 110
    fi
  done

else
  echo -e "\e[31mError:\e[0m This file already exist in container ${container_id}: ${upload_file}" >&2
  echo -e "\e[31mResponse:\e[0m ${upload_test}" >&2
  exit 102
fi

echo "Closing upload"
conf_res=$(curl ${curl_args} -XPUT "${upload_server}/nfs_store/chunk/${container_id}.json?user_email=${upload_user_email}&user_token=${upload_user_token}" \
  -F "activity_log_id=${activity_log_id}" \
  -F "activity_log_type=${activity_log_type}" \
  -F "container_id=${container_id}" \
  -F "do=done" \
  -F "uploaded_ids=${uploaded_ids}")

res=$?
echo "${conf_res}"
if [ ${res} == 0 ] && [ "$(echo ${conf_res} | grep '"result":"done"')" ]; then
  echo -e "\e[32mUploaded file successfully to container ${container_id}:\e[0m ${upload_file}"
else
  echo -e "\e[31mError:\e[0m Failed to confirm upload of file: ${upload_file}" >&2
  echo -e "\e[31mResponse:\e[0m ${conf_res}" >&2
  exit 121
fi

exit 0
