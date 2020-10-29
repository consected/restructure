#!/bin/bash
# First, run brakeman
bin/brakeman -q --summary > /tmp/fphs-brakeman-summary.txt
cat /tmp/fphs-brakeman-summary.txt
echo > log/test.log
# Run the rspec tests in parallel. Use the first arg to define the path if needed
export PARALLEL_TEST_PROCESSORS=8
bundle exec rake parallel:spec[$1]
