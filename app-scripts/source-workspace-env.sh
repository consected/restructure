#!/bin/bash
# Source with `source app-scripts/source-workspace-env.sh` to set up 
# the workspace environment
# To show the workspace environment, set SHOW_WS_ENV to a non-empty value
# before sourcing this script: 
# Example:
# SHOW_WS_ENV=t source app-scripts/source-workspace-env.sh
#
cd "$(dirname -- "${BASH_SOURCE[0]}")/.."

if [ ! -f ".env" ]; then
  echo ".env file not found! Ensure it has the value TEST_ENV_SET=ws<x> at a minimum."
  return 1
fi

set -a
source '.env'
set +a

LATEST_NODE=$(ls -At "${HOME}/.nvm/versions/node" | grep v | head -n 1)

export PATH="${HOME}/.rbenv/bin:$PATH"
export PATH="${HOME}/.local/bin:$PATH"
export PATH="${HOME}/.nvm/versions/node/${LATEST_NODE}/bin:$PATH"
eval "$(rbenv init -)"
if [ "${SHOW_WS_ENV}" ]; then
  echo "TEST_ENV_SET: ${TEST_ENV_SET}"
  echo "bundle path: $(which bundle)"
  echo "ruby version: $(ruby -v)"
fi
