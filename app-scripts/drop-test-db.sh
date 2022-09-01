DB_BASE_NAME=${DB_BASE_NAME:=restr}

function drop() {

  DBNAME=${DB_BASE_NAME}_test${DBNUM}
  APPENV=test
  SCHEMA_NAME=ml_app
  DBOWNER=$(whoami)

  psql -c "drop database $DBNAME;" -h localhost -U postgres

}

if [ -z $1 ]; then
  PARALLEL=$(nproc)
else
  PARALLEL=$1
fi

if [ -z ${PARALLEL} ]; then
  echo "Single drop"
  drop
else
  echo "Drop ${PARALLEL} databases"
  for i in $(seq 1 ${PARALLEL}); do
    if [ ${i} == 1 ]; then
      DBNUM=''
    else
      DBNUM=${i}
    fi
    drop
  done
fi
