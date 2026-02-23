#!/bin/bash

RAILS_ENV=test bundle exec rails assets:clobber
RAILS_ENV=test bundle exec rails assets:precompile
rm -rf tmp/cache public/handlebars-*/* tmp/handlebars-*/*
