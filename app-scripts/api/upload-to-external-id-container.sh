#!/bin/bash
export upload_user_email='xyz-api@api.fphs'
export upload_user_token='abcdefg'
export upload_server="https://filestore.fphs.link"
export upload_app_type=7

export curl_args="-s"

fn_suffix='_diffusion'
export activity_log_type='activity_log__ipa_assignment_session_filestore'
export container_name='mri'
file_ext='.tar.gz'

curr_dir="$(pwd)"
input_dir="$1"
cd "$(dirname $0)"
script_dir="$(pwd)"
upload_script="${script_dir}/upload-to-filestore.sh"

if [ -z "${input_dir}" ] || [ ! -d "${input_dir}" ]; then
  echo -e "\e[31mError:\e[0m The first argument must be set, and must point to the input directory" >&2
  exit 1
fi

if [ ! -f "${upload_script}" ]; then
  echo -e "\e[31mError:\e[0m upload script not found at '${upload_script}'" >&2
  exit 2
fi

for p in md5sum curl awk; do
  which ${p} > /dev/null
  res=$?
  if [ ${res} != 0 ]; then
    echo -e "\e[31mError ${res}:\e[0m Program "${p}" must be installed" >&2
    exit 15
  fi
done

cd ${input_dir}
input_dir="$(pwd)"
mkdir -p in-progress failed backup success
[ "$(ls in-progress)" ] && mv in-progress/* backup/

if [ ! "$(ls *${file_ext} 2> /dev/null)" ]; then
  echo -e "\e[31mError:\e[0m No files to process in the input directory '${input_dir}'" >&2
  if [ "$(ls failed 2> /dev/null)" ]; then
    echo "Failed files are in '${input_dir}/failed'" >&2
  fi

  exit 3
fi

function get_upload_details() {
  local ipa_id="$1"
  local auth_string="use_app_type=${upload_app_type}&user_email=${upload_user_email}&user_token=${upload_user_token}"
  local url="${upload_server}/reports/ipa_files_api__ipa_find_container.json?search_attrs%5Bsession_type%5D=${container_name}&search_attrs%5Bipa_id%5D=${ipa_id}&${auth_string}"
  activities="$(curl ${curl_args} ${url})"
  res=$?
  if [ ${res} != 0 ]; then
    echo -e "\e[31mError ${res}:\e[0m Failed to get details for IPA ID ${ipa_id}" >&2
    echo "URL: ${upload_server}/reports/ipa_files_api__ipa_find_container.json?search_attrs%5Bsession_type%5D=${container_name}&search_attrs%5Bipa_id%5D=${ipa_id}&<auth string>"
    echo "${activities}" >&2
    return 21
  fi
  # echo "${activities}"
  container_id=$(echo "${activities}" | jq -r ".results[0] .container_id")
  activity_log_id=$(echo "${activities}" | jq -r ".results[0] .activity_log_id")
  master_id=$(echo "${activities}" | jq -r ".results[0] .master_id")
}

function loop_input_dir() {
  cd "${input_dir}"
  local failed_files=0
  for f in $(ls *${file_ext}); do
    cd "${input_dir}"

    if [ ! -f "${f}" ]; then
      continue
    fi
    echo "Processing: ${f}"
    local ipa_id="${f/${file_ext}/}"
    echo "IPA ID: ${ipa_id}"

    # Renaming file and moving to in-progress directory
    local new_fn="${ipa_id}${fn_suffix}${file_ext}"
    local in_progress_f="in-progress/${new_fn}"
    local failed_f="failed/${f}"
    local success_f="success/${f}"
    mv "${f}" "${in_progress_f}"

    get_upload_details ${ipa_id}
    res=$?
    if [ ${res} != 0 ]; then
      echo -e "\e[31mError ${res}:\e[0m Failed to get details for IPA ID ${ipa_id}. File moved to '${failed_f}'" >&2
      mv "${in_progress_f}" "${failed_f}"
      failed_files=31
      continue
    fi

    container_id=${container_id} \
      activity_log_id=${activity_log_id} \
      master_id=${master_id} \
      upload_file="${in_progress_f}" \
      upload_filename="${new_fn}" \
      "${upload_script}"

    res=$?

    cd "${input_dir}"
    if [ ${res} != 0 ]; then
      echo -e "\e[31mError ${res}:\e[0m Upload failed for '${in_progress_f}'" >&2
      mv "${in_progress_f}" "${failed_f}"
      failed_files=32
      continue
    fi

    mv "${in_progress_f}" "${success_f}"
  done

  return ${failed_files}
}

date

loop_input_dir
res=$?
if [ ${res} != 0 ]; then
  echo -e "\e[31mFailed files\e[0m"
  cd "${input_dir}"
  ls failed
else
  echo "All files uploaded successfully"
fi

cd "${curr_dir}"
date
