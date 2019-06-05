#!/bin/bash

export org_upper=FPHS
export target_initials_upper=$(echo "${target_name}" | tr a-z A-Z)
export target_initials_lower=$(echo "${target_name}" | tr A-Z a-z)

BASEDIR=$(dirname $0)
CURRDIR=$(pwd)
cd ${BASEDIR}

if [ -z "${app_schema}" ]; then
  echo "Variable 'app_schema' is not set. Exiting"
  exit
fi

if [ -z "${target_name}" ]; then
  echo "Variable 'target_name' is not set. Exiting"
  exit
fi

export target_name
export app_schema
export sql_dir='db/app_specific'
export target_dir=${BASEDIR}/../${target_name}
export app_dirname=${target_name}
export app_configs="${BASEDIR}/../../app_configs"
export target_name_us=$(echo ${target_name} | tr "[ \-]" "_")

if [ -d "${target_dir}" ]; then
  echo "Directory '${target_dir}' already exists."
  # exit
else
  echo "Creating '${target_dir}'"
fi

mkdir -p ${target_dir}

module_list="0-scripts adverse-events inex mednav navigation phone-screen protocol-deviations tracker z-sync"

modules=$(echo ${module_list} | tr " " "\n")

export body='$body'
for module in ${modules}
do
  for curr_file in ./aws-db/${module}/*
  do
    mkdir -p ${target_dir}/aws-db/${module}
    envsubst < ${curr_file} > ${target_dir}/${curr_file}
  done
done

cd ${CURRDIR}
envsubst < "${app_configs}/baseline study_config.json" > "${app_configs}/${target_name}_config.json"
