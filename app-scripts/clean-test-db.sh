#!/bin/bash
# Quickly clean and reset the test database (just a single database, not all for parallel tests)


export USE_PG_UNAME=${USE_PG_UNAME:=$(whoami)}
DBNUM=${DBNUM:=${TEST_ENV_NUMBER}}
export DBNUM
echo "Cleaning a single test database (number: ${DBNUM} and test environment code: ${TEST_ENV_SET}) with user Postgres user: ${USE_PG_UNAME}"
app-scripts/drop-test-db.sh 1 && \
  app-scripts/create-test-db.sh 1
rm -rf /var/tmp/nfs_store_tmp${TEST_ENV_NUMBER}${TEST_ENV_SET} && \
  rm -rf /var/tmp/nfs_store_test${TEST_ENV_NUMBER}${TEST_ENV_SET}
