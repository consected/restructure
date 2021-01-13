#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: app-scripts/copy-to-restructure.sh <DESTINATION FOLDER>"
  echo "For example: app-scripts/copy-to-restructure.sh ../../restructure/restructure/"
  exit 1
fi

DEST="$1"
EXCLUDE='database.yml favicon.png structure.sql'

cd $(dirname $0)/..

if [ -d public/assets ]; then
  bundle exec rake assets:clobber
fi

for FROM in app bin config db/migrate db/seeds db/table_generators db/app_migrations/data_requests app-scripts/supporting \
  lib public/fonts public/app_specific/data_requests script spec \
  vendor/assets/images vendor/assets/javascripts vendor/assets/stylesheets; do
  mkdir -p ${DEST}/${FROM}
  rsync -av --update --exclude="${EXCLUDE}" ${FROM}/ ${DEST}/${FROM}/
done

mkdir -p ${DEST}/docs
mkdir -p ${DEST}/db/dumps/development-data

for FROM in \
  yarn.lock package.json \
  docs/filestore-setup.md \
  db/schema.rb db/seeds.rb db/dumps/development-data/data-only-dump.sql db/demo-data.zip \
  app-scripts/add_admin.sh app-scripts/api-get-container-id.sh app-scripts/parallel_test.sh \
  app-scripts/release_and_build.sh \
  app-scripts/setup_filestore_app.sh app-scripts/setup-dev-filestore.sh app-scripts/upload-to-filestore.sh \
  app-scripts/upversion.rb app-scripts/validate_file_signature.sh \
  app-scripts/create-demo-db.sh app-scripts/create-test-db.sh app-scripts/drop-test-db.sh \
  public/.gitignore public/*.html public/robots.txt \
  public/app_specific/app_data_requests.css \
  .gitignore .rspec_parallel .rubocop.yml .ruby-version .solargraph.yml config.ru \
  Gemfile* Rakefile vendor/assets/config.json; do
  cp -u ${FROM} ${DEST}/${FROM}
done

# Removed db/structure.sql

mkdir -p ${DEST}/log
mkdir -p ${DEST}/tmp

cd ${DEST}

grep --recursive harvard.edu *
