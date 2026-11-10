#!/bin/bash
# Run the Jasmine specs in spec/javascripts.
#   app-scripts/jasmine-serve.sh            serve the specs on http://localhost:8888 and open them in Firefox
#   app-scripts/jasmine-serve.sh headless   run the specs in a headless Firefox started by the runner, then exit
# The exit status is the runner's, so it is non-zero if any spec fails.
#
# The specs load every public/assets/application-*.js bundle. If stale bundles with different digests
# are present, the run fails with "redeclaration of let ..."; clean them with
# app-scripts/clean-test-assets-and-cache.sh

if [ "$1" == 'headless' ]; then
  runner_args='runSpecs --browser=headlessFirefox'
else
  runner_args=serve
fi

if [ -z "${DBUS_SESSION_BUS_ADDRESS}" ]; then
  export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
fi

JS_SETUP=true SKIP_BROWSER_SETUP=true SKIP_DB_SETUP=true SKIP_APP_SETUP=true bundle exec rspec spec/system/js_asset_spec.rb

if [ "$1" != 'headless' ]; then
  # serve only starts the server, so open it in a visible browser
  (
    sleep 3
    firefox http://localhost:8888
  ) &
fi

npx jasmine-browser-runner ${runner_args}
status=$?
echo 'Done'
exit ${status}
