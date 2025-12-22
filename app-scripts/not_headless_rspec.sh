#!/bin/bash
NOT_HEADLESS=true RUN_APP_SPECS=true FEATURE_DEBUG=true bundle exec rspec "$@"