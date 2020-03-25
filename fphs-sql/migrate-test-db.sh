BASEDIR=$0

function migrate {
  bundle exec rake db:migrate
}

if [ ! -z $1 ]
then
  PARALLEL=$1
fi

if [ -z ${PARALLEL} ]
then
  echo "Single migrate"
  migrate
else
  echo "migrate ${PARALLEL} databases"
  for i in $(seq 1 ${PARALLEL})
  do
    if [ ${i} == 1 ]
    then
      TEST_ENV_NUMBER=''
    else
      TEST_ENV_NUMBER=${i}
    fi
    if [ "${i}" == "${PARALLEL}" ]
    then
      migrate
    else
      migrate &
    fi
  done
fi
