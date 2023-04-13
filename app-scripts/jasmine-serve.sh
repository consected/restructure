#!/bin/bash

if [ "$1" == 'headless' ]; then
  runas=runSpecs
  export browserarg='--headless'
else
  runas=serve
fi

rm public/assets/application-*
JS_SETUP=true SKIP_BROWSER_SETUP=true SKIP_DB_SETUP=true SKIP_APP_SETUP=true rspec spec/features/js_asset_spec.rb

if [ "${browserarg}" ]; then
  killall firefox 2> /dev/null
fi

$(
  sleep 3
  firefox ${browserarg} http://localhost:8888
) &

npx jasmine-browser-runner ${runas}
