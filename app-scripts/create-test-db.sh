BASEDIR=$0
DB_BASE_NAME=${DB_BASE_NAME:=restr}

function setup() {

  DBNAME=${DB_BASE_NAME}_test${DBNUM}
  DBOWNER=$(whoami)

  cd $(dirname ${BASEDIR})

  psql -c "create database $DBNAME" -U postgres -h localhost
  psql -d $DBNAME < "../db/structure.sql"  -U postgres -h localhost
  psql -d $DBNAME -c "create schema if not exists bulk_msg;"  -U postgres -h localhost
  psql -d $DBNAME -c "create schema if not exists ref_data;" -U postgres -h localhost

  RAILS_ENV=test TEST_ENV_NUMBER=${DBNUM} bundle exec rails db:seed
}

if [ -z $1 ]; then
  PARALLEL=$(nproc)
else
  PARALLEL=$1
fi

if [ -z ${PARALLEL} ]; then
  echo "Single setup"
  setup
else
  echo "Setup ${PARALLEL} databases"
  for i in $(seq 1 ${PARALLEL}); do
    if [ ${i} == 1 ]; then
      DBNUM=''
    else
      DBNUM=${i}
    fi
    if [ "${i}" == "${PARALLEL}" ]; then
      setup
    else
      setup &
    fi
  done

  # Ensure entries have been made in .pgpass for these DBs
fi
