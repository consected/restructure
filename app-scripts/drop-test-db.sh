DB_BASE_NAME=${DB_BASE_NAME:=restr}

function drop() {

  DBNAME=${DB_BASE_NAME}_test${DBNUM}
  APPENV=test
  SCHEMA_NAME=ml_app
  DBOWNER=$(whoami)

  sudo -u postgres psql -c "drop database $DBNAME;"

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
