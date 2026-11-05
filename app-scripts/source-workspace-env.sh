#!/bin/bash
# Source with `source app-scripts/source-workspace-env.sh` to set up 
# the workspace environment
#
cd "$(dirname -- "${BASH_SOURCE[0]}")/.."

if [ ! -f ".env" ]; then
  echo ".env file not found! Ensure it has the value TEST_ENV_SET=ws<x> at a minimum."
  return 1
fi

source '.env'
export TEST_ENV_SET

export PATH=$HOME/.rbenv/bin:$PATH
export PATH=~/.local/bin:$PATH
eval "$(rbenv init -)"
echo TEST_ENV_SET: $TEST_ENV_SET
echo bundle path: $(which bundle)
echo ruby version: $(ruby -v)
