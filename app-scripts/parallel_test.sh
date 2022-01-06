#!/bin/bash
# First, run brakeman
if [ "${NO_BRAKEMAN}" != 'true' ]; then
  bin/brakeman -q --summary > /tmp/fphs-brakeman-summary.txt
  cat /tmp/fphs-brakeman-summary.txt
fi
echo "Setup filestore"
app-scripts/setup-dev-filestore.sh
echo > log/test.log
# Run the rspec tests in parallel. Use the first arg to define the path if needed
export PARALLEL_TEST_PROCESSORS=${PARALLEL_TEST_PROCESSORS:=$(nproc)}
bundle exec rake parallel:spec[$1]
