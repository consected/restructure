#!/bin/bash

modules=adverse-events inex mednav navigation phone-screen protocol-deviations tracker z-sync

BASEDIR =$(dirname $0)
cd ${BASEDIR}

if [ -z "${target_name}" ]
then
  echo "Variable 'target_name' is not set. Exiting"
  exit
fi

mkdir ../${target_name}


cd ${BASEDIR}/aws-db

for module in ${modules}
do
  for curr_file in ${module}/*
  do
    # envsubst < ${curr_file} > ${new_file}

  done
done
