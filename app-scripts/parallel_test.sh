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

if [ -z "$@" ]; then
  specs='spec/controllers spec/features spec/javascripts spec/jobs spec/models spec/requests spec/routing'
else
  specs=$@
fi

rm -f tmp/working_failing_specs.log

for spec in ${specs}; do
  bundle exec rake parallel:spec[${spec}]
  cat tmp/failing_specs.log >> tmp/working_failing_specs.log
done

mv tmp/working_failing_specs.log tmp/failing_specs.log
