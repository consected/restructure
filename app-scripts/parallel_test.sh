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

require_arg_value() {
  if [ -z "$2" ] || [[ "$2" == --* ]]; then
    echo "Missing value for $1"
    exit 2
  fi
}

show_help() {
  cat <<EOF
Usage: $(basename "$0") [options] [spec_path ...]

Options:
  --no-run                        Parse options but do not run specs
  --run-restests                  Run the retest script for failed specs
  --browser BROWSER               Browser to use: chrome or firefox
  --no-clean-db                   Skip cleaning the test database
  --no-brakeman                   Skip Brakeman security analysis
  --skip-brakeman                 Alias for --no-brakeman
  --sudo-postgres                 Use sudo as postgres when cleaning the database
  --use-pg-uname USERNAME         PostgreSQL username to use when cleaning the database
  --use-pg-host HOST              PostgreSQL host to use instead of sudo-based cleanup
  --skip-zeitwerk                 Skip the Zeitwerk check
  --parallel-test-processors N    Number of parallel test processors to use
  --run-app-specs VALUE           Set RUN_APP_SPECS, for example true or false
  --help, -h                      Show this help message and exit

Any remaining arguments are treated as spec paths.
EOF
}

while true; do
  case "$1" in
    --help|-h)
      show_help
      exit 0
      ;;
    --no-run)
      NO_RUN=true
      shift
      ;;
    --run-restests)
      RUN_RESTESTS=true
      shift
      ;;
    --browser)
      require_arg_value "$1" "$2"
      BROWSER="$2"
      shift 2
      ;;
    --no-clean-db)
      NO_CLEAN_DB=true
      shift
      ;;
    --no-brakeman)
      NO_BRAKEMAN=true
      shift
      ;;
    --skip-brakeman)
      SKIP_BRAKEMAN=true
      shift
      ;;
    --sudo-postgres)
      SUDO_POSTGRES=true
      shift
      ;;
    --use-pg-uname)
      require_arg_value "$1" "$2"
      USE_PG_UNAME="$2"
      shift 2
      ;;
    --use-pg-host)
      require_arg_value "$1" "$2"
      USE_PG_HOST="$2"
      shift 2
      ;;
    --skip-zeitwerk)
      SKIP_ZEITWERK=true
      shift
      ;;
    --parallel-test-processors)
      require_arg_value "$1" "$2"
      PARALLEL_TEST_PROCESSORS="$2"
      shift 2
      ;;
    --run-app-specs)
      require_arg_value "$1" "$2"
      RUN_APP_SPECS="$2"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done


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
  BRAKEMAN_EXIT_CODE=$?
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
procs=$(nproc)
export PARALLEL_TEST_PROCESSORS=${PARALLEL_TEST_PROCESSORS:=$((procs / 2))}

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

# Clean up the temporary nfs_store directories
rm -rf /var/tmp/nfs_store_tmp*
rm -rf /var/tmp/nfs_store_test*

for spec in ${specs}; do
  echo "========================================================================"
  echo "==>>>> Running parallel specs for '${spec}'"
  echo "========================================================================"
  echo "========================================================================" >> tmp/working_failing_specs.log
  echo "==>>>> Running parallel specs for '${spec}'" >> tmp/working_failing_specs.log
  echo "==>>>> $(date)" >> tmp/working_failing_specs.log
  echo "========================================================================" >> tmp/working_failing_specs.log

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
echo "Runs with failures: $(grep 'Failures: ' tmp/working_failing_specs.log | wc -l)" >> tmp/working_failing_specs.log
echo "==>>>> $(date)" >> tmp/working_failing_specs.log
echo "========================================================================" >> tmp/working_failing_specs.log
mv tmp/working_failing_specs.log tmp/failing_specs.log

echo "Started at  ${start_date}" >> tmp/failing_specs.log
echo "Finished at $(date)" >> tmp/failing_specs.log

if [ "${BRAKEMAN_EXIT_CODE}" -ne 0 ]; then
  echo "Brakeman found security issues. Check /tmp/fphs-brakeman-summary.txt for details."
  cat /tmp/fphs-brakeman-summary.txt
fi

if [ -f tmp/parallel_specs_failed.txt ]; then
  $(dirname "$0")/clean-test-db.sh
  cat tmp/failing_specs.log
  echo "Parallel specs failed. Check tmp/failing_specs.log for details."
  echo "Running retest for failed specs"
  $(dirname "$0")/parallel_test_retest.sh
  res=$?
  cat tmp/retest_output.log >> tmp/failing_specs.log
  exit $res
else
  echo "All parallel specs passed."
  echo "All parallel specs passed."  >> tmp/failing_specs.log
  exit 0
fi


