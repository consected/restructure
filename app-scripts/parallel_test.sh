#!/bin/bash
# BROWSER: 'chrome' (default) or 'firefox'
# RUN_RESTESTS: If set to 'true', the script will run the retest script for failed specs.
# NO_CLEAN_DB: If set to 'true', the script will skip cleaning the test database.
# NO_BRAKEMAN: If set to 'true', the script will skip running Brakeman security analysis.
# SKIP_BRAKEMAN: equivalent to NO_BRAKEMAN. 
# SUDO_POSTGRES: If set, the script will use sudo (as postgres) to clean the database.
# USE_PG_UNAME: If set, the script will use this database user to connect to PostgreSQL when cleaning the database.
# USE_PG_HOST: If set, the script will not use sudo to clean the database, and will connect to the specified PostgreSQL host via a TCP port.
# SKIP_ZEITWERK: If set to 'true', the script will skip checking Zeitwerk.
# PARALLEL_TEST_PROCESSORS: Number of parallel processes to use for running tests. Defaults to number of CPU cores.
# RUN_APP_SPECS: Set to 'false' to avoid running the environment specific app specs
#
# NOTE: if running without SUDO_POSTGRES, the Postgres user must have the following permission attributes:
# - CREATEDB
# - CREATEROLE
# - LOGIN
# These can be set by a Postgres superuser with the command:
# ALTER USER <username> WITH CREATEDB CREATEROLE LOGIN;


BROWSER=${BROWSER:-chrome}
export USE_PG_UNAME=${USE_PG_UNAME:=$(whoami)}
if [ "${SUDO_POSTGRES}" ]; then
  unset USE_PG_UNAME
fi

export RUN_APP_SPECS=${RUN_APP_SPECS:-true}

if [ "${RUN_RESTESTS}" == 'true' ]; then
  $(dirname $0)/clean-test-db.sh
  echo "Running retest for failed specs"
  $(dirname $0)/parallel_test_retest.sh
  exit $?
fi

echo > log/test.log
echo > tmp/failing_specs.log
echo > tmp/working_failing_specs.log

# Clear a variable that is often set in the session
unset QUICK
unset RUBY_DEBUG_OPEN

if [ ! "${USE_PG_HOST}" ] && [ ! "${USE_PG_UNAME}" ]&& [ "${NO_CLEAN_DB}" != 'true' ]; then
  echo "sudo is required to clean the database. Enter your password if prompted"
  if ! sudo whoami; then
    echo "Failed to get sudo"
    exit 101
  fi
fi

# Ensure the tests run cleanly
export DISABLE_SPRING=1
bundle exec spring stop

# First, run brakeman
if [ "${NO_BRAKEMAN}" != 'true' ] && [ "${SKIP_BRAKEMAN}" != 'true' ]; then
  echo "Running brakeman"
  bin/brakeman -q --summary > /tmp/fphs-brakeman-summary.txt
  cat /tmp/fphs-brakeman-summary.txt
fi

echo "Setup filestore"
app-scripts/setup-dev-filestore.sh
if [ $? != 0 ]; then
  echo "Failed to set up filestore"
  exit 6
fi

if [ "${NO_CLEAN_DB}" != 'true' ]; then
  echo "Clean database"
  app-scripts/drop-test-db.sh > /dev/null
  app-scripts/create-test-db.sh > /dev/null
  reset
fi

if [ "${SKIP_ZEITWERK}" != 'true' ]; then
  # Check zeitwerk before continuing
  bundle exec rails zeitwerk:check
  if [ $? != 0 ]; then
    echo "Zeitwerk test failed"
    exit 7
  fi

  export CI=true
fi

# Run the rspec tests in parallel. Use the first arg to define the path if needed
export PARALLEL_TEST_PROCESSORS=${PARALLEL_TEST_PROCESSORS:=$(nproc)}

if [ -z "$@" ]; then
  specs='spec'
else
  specs="$@"
fi

start_date=$(date)

echo "========================================================================"
echo "Number of processes: ${PARALLEL_TEST_PROCESSORS}"
echo "Requested specs: ${specs}"
pwd
echo "========================================================================"

rm -f tmp/parallel_specs_failed.txt

for spec in ${specs}; do
  echo "========================================================================"
  echo "==>>>> Running parallel specs for '${spec}'"
  echo "========================================================================"
  echo "========================================================================" >> tmp/working_failing_specs.log
  echo "==>>>> Running parallel specs for '${spec}'" >> tmp/working_failing_specs.log
  echo "==>>>> $(date)" >> tmp/working_failing_specs.log
  echo "========================================================================" >> tmp/working_failing_specs.log
  # Clean up the temporary nfs_store directories
  rm -rf /var/tmp/nfs_store_tmp*
  rm -rf /var/tmp/nfs_store_test*

  RAILS_ENV=test bundle exec rake parallel:spec["${spec}"] || echo 'failed' > tmp/parallel_specs_failed.txt &
  while ! pgrep -f 'ruby bin/rspec' > /dev/null; do
    sleep 5
  done
  sleep 2
  # Display the running specs
  ps aux | grep 'ruby bin/rspec'

  # Wait for all specs to finish
  while pgrep -f 'ruby bin/rspec' > /dev/null; do
    sleep 5
  done
  # Kill the locked parent
  sleep 5
  if [ "$(pgrep -f 'bin/parallel_test')" ]; then
    kill $(pgrep -f 'bin/parallel_test')
  fi
  cat tmp/failing_specs.log >> tmp/working_failing_specs.log
done

echo "========================================================================" >> tmp/working_failing_specs.log
echo "All Done" >> tmp/working_failing_specs.log
echo "Runs with Failures: $(grep 'Failures: ' tmp/failing_specs.log | wc -l)" >> tmp/working_failing_specs.log
echo "==>>>> $(date)" >> tmp/working_failing_specs.log
echo "========================================================================" >> tmp/working_failing_specs.log
mv tmp/working_failing_specs.log tmp/failing_specs.log

echo "Started at  ${start_date}" >> tmp/failing_specs.log
echo "Finished at $(date)" >> tmp/failing_specs.log

if [ -f tmp/parallel_specs_failed.txt ]; then
  $(dirname $0)/clean-test-db.sh
  cat tmp/failing_specs.log
  echo "Parallel specs failed. Check tmp/failing_specs.log for details."
  echo "Running retest for failed specs"
  $(dirname $0)/parallel_test_retest.sh >> tmp/failing_specs.log 2>&1
else
  echo "All parallel specs passed."
  echo "All parallel specs passed."  >> tmp/failing_specs.log
  exit 0
fi


