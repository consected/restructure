#!/bin/bash
# Retest failed specs from the last parallel_test.sh run. This is based on the
# tmp/parallel_specs_failed.txt file created by that script.
# If you just want to see which specs would be retested, run with the --no-run option.

if [ ! -f tmp/parallel_specs_failed.txt ]; then
  echo "No failed specs to retest."
  exit 0
fi

if [ "$1" == "--no-run" ]; then
  NO_RUN=true
fi

echo "Retesting failed specs"
old_ifs=$IFS
IFS=$'\n'
retest=''
for line in $(grep -P '(\e\[[0-9]+m)?rspec ' tmp/failing_specs.log) ; do 
  [[ $line =~ rspec\ ([a-zA-Z0-9_\./]+) ]]
  retest="${retest}"$'\n'"$(echo ${BASH_REMATCH[1]})"
done 
retest=$(echo "${retest}" | uniq)
IFS=$old_ifs

if [ -z "${retest}" ]; then
  echo "No failed specs found in tmp/failing_specs.log"
  echo "No failed specs found in tmp/failing_specs.log" >> tmp/failing_specs.log
  exit 0
fi

echo "Retesting: ${retest}"
echo "bundle exec rspec -f d "$retest
if [ -z "${NO_RUN}" ]; then
  echo "Running retest..."
else
  echo "NO_RUN is set. Skipping retest run."
  exit 0
fi

set -o pipefail
bundle exec rspec -f d $retest 2>&1 | tee tmp/retest_output.log
res=$?
set +o pipefail

if [ "$QUIETLY" == "true" ]; then
  exit $res
fi

if [ $res != 0 ]; then
  echo "Retest of failed specs did not pass - results in tmp/retest_output.log"
  exit $res
else
  echo "Retest of failed specs passed."
  exit 0
fi