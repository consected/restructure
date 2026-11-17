#!/bin/bash
# List failed specs to allow easy retesting of only those specs

if [ $# -ne 1 ]; then
  echo "Usage: $0 <log_file>"
  echo "If no failed specs are found, the script will exit with a non-zero exit code."
  echo "Example: $0 tmp/retest_output.log"
  echo "Run the tests this script returns:"
  echo "    bundle exec rspec --format progress \$($0 tmp/retest_output.log || echo '--dry-run')"
  echo "NOTE: To avoid a full rerun of all specs, this just returns the rspec version if no failed specs are found."
  exit 1
fi

# echo "List failed specs"
old_ifs=$IFS
IFS=$'\n'
retest=''
for line in $(grep -P '(\e\[[0-9]+m)?rspec ' $1) ; do 
  [[ $line =~ rspec\ ([a-zA-Z0-9_\./]+) ]]
  retest="${retest}"$'\n'"$(echo ${BASH_REMATCH[1]})"
done 
retest=$(echo "${retest}" | uniq)
IFS=$old_ifs
echo ${retest}
if [ -z "${retest}" ]; then
  exit 1
else
  exit 0
fi
