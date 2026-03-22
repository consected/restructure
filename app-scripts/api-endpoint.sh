#!/bin/bash
# Generate a full list of API endpoints for the app, excluding admin routes (which are not accessible through the public API). 
# Arguments:
#   Comma separated list of app types to filter the routes by. If not provided, all routes will be included.
# Example usage:
#   bundle exec rails routes # full set of routes
#   bundle exec rails routes 1,2  # routes for app types 1 and 2 only
# NOTE: this may take some time to return, since the environment has to be fully loaded to include all the dynamic definitions.

FPHS_LOAD_APP_TYPES="$1" bundle exec rails routes 2>/dev/null | grep --invert ' /admin'