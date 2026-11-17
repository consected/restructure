#!/bin/bash
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Do not start if another RSpec process is using this workspace
"${script_dir}/check_rspec_processes.sh" "${script_dir}/.." || exit 1

RUN_APP_SPECS=true FEATURE_DEBUG=true bundle exec rspec "$@"