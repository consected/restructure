#!/bin/bash
# See README.md to see information on usage

# Prior to calling, export the following environment variables:

# # The user credentials
# export upload_user_email='<api username>'
# export upload_user_token='<private token>'
# # The server to upload to
# export upload_server="https://<server domain name>"
# # Add _diffusion to the filename before uploading
# export fn_suffix='_diffusion'
# # Sets the IPA app
# export upload_app_type=7
# # Sets up the container types to load to
# export activity_log_type='activity_log__study_assignment_session_filestore'
# export container_name='mri'
# # File types to upload
# export file_ext='.tar.gz'
# # External ID attribute to find containers on
# export external_id_attribute='study_id'
# # Resource name for the report used to match IDs to containers
# export report_name='study_files_api__study_find_container'

# To run the script, specify the first argument with the directory to upload from
# ./upload-to-external-id-container.sh '<absolute path to directory>'

export curl_args=${curl_args:-"-s"}

curr_dir="$(pwd)"
input_dir="$1"
cd "$(dirname $0)"
script_dir="$(pwd)"
upload_script="${script_dir}/upload-to-filestore.sh"

if [ -z "${upload_user_email}" ] || [ -z "${upload_user_token}" ] || [ -z "${upload_server}" ]; then
  echo -e "\e[31mError:\e[0m The environment variables upload_user_email, upload_user_token, and upload_server must be set" >&2
  exit 4
fi

if [ -z "${input_dir}" ] || [ ! -d "${input_dir}" ]; then
  echo -e "\e[31mError:\e[0m The first argument must be set, and must point to the input directory" >&2
  exit 1
fi

if [ ! -f "${upload_script}" ]; then
  echo -e "\e[31mError:\e[0m upload script not found at '${upload_script}'" >&2
  exit 2
fi

for p in md5sum curl awk split; do
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

function set_app_or_exit() {
  echo "Attempting initial connection to set app type to ${upload_app_type}"
  local auth_string="use_app_type=${upload_app_type}&user_email=${upload_user_email}&user_token=${upload_user_token}"
  local url="${upload_server}/reports?use_app_type=${upload_app_type}"
  local app_set_res="$(curl ${curl_args} ${url})"
  res=$?
  if [ ${res} != 0 ]; then
    echo -e "\e[31mcURL Error ${res}:\e[0m Failed to set up the app" >&2
    echo "${app_set_res}" >&2
    exit 41
  fi

  if [ "$(echo "${app_set_res}" | grep 'You need to sign in')" ]; then
    echo -e "\e[31mError ${res}:\e[0m Authentication details are incorrect" >&2
    echo "${app_set_res}" >&2
    exit 42
  fi

}

function get_upload_details() {
  local ext_id="$1"
  local auth_string="use_app_type=${upload_app_type}&user_email=${upload_user_email}&user_token=${upload_user_token}"
  local report_url="${upload_server}/reports/${report_name}.json?search_attrs%5Bsession_type%5D=${container_name}&search_attrs%5B${external_id_attribute}%5D=${ext_id}"
  local url="${report_url}&${auth_string}"
  activities="$(curl ${curl_args} ${url})"
  res=$?
  if [ ${res} != 0 ]; then
    echo -e "\e[31mcURL Error ${res}:\e[0m Failed to get details for Participant ID ${ext_id}" >&2
    echo "URL: ${report_url}&<auth string>"
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
    echo "=========="
    echo "Processing: ${f}"
    local ext_id="${f/${file_ext}/}"
    echo "Participant ID: ${ext_id}"

    # Renaming file and moving to in-progress directory
    local new_fn="${ext_id}${fn_suffix}${file_ext}"
    local in_progress_f="in-progress/${new_fn}"
    local failed_f="failed/${f}"
    local success_f="success/${f}"
    mv "${f}" "${in_progress_f}"

    get_upload_details ${ext_id}
    res=$?
    if [ ${res} != 0 ]; then
      echo -e "\e[31mError ${res}:\e[0m Failed to get details for Participant ID ${ext_id}. File moved to '${failed_f}'" >&2
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

echo "Started: $(date)"
set_app_or_exit

loop_input_dir
res=$?
if [ ${res} == 0 ]; then
  echo "All files uploaded successfully"
fi

cd "${input_dir}"
if [ "$(ls failed 2> /dev/null)" ]; then
  echo -e "\e[31mFailed files:\e[0m There are failed files in '${input_dir}/failed'" >&2
fi

cd "${curr_dir}"
echo "Finished: $(date)"
