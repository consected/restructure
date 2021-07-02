BASEDIR=$0
DB_BASE_NAME=${DB_BASE_NAME:=fpa}

echo "Creating: ${DB_BASE_NAME}"

function setup() {

  DBNAME=${DB_BASE_NAME}_test${DBNUM}
  DBOWNER=$(whoami)

  cd $(dirname ${BASEDIR})

  sudo -u postgres psql -c "create database $DBNAME with owner $DBOWNER;"
  psql -d $DBNAME < "../db/structure.sql"
  psql -d $DBNAME -c "create schema if not exists bulk_msg;"
  psql -d $DBNAME -c "create schema if not exists ref_data;"

  RAILS_ENV=test TEST_ENV_NUMBER=${DBNUM} bundle exec rake db:seed
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
